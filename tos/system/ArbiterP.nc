/*
 * Copyright (c) 2011, Eric B. Decker
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
 
/**
 * Please refer to TEP 108 for more information about this component and its
 * intended use.<br><br>
 *
 * This component provides the Resource, ResourceRequested, ArbiterInfo, 
 * and ResourceDefaultOwner interfaces and uses the ResourceConfigure interface as
 * described in TEP 108.  It provides arbitration to a shared resource.
 *
 * A Queue is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the queue is checked and the next user
 * that has a pending request will ge granted control of the resource.  If
 * there are no pending requests, then the user of the ResourceDefaultOwner
 * interface gains access to the resource, and holds onto it until
 * another user makes a request.
 *
 * @param <b>default_owner_id</b> -- The id of the default owner of this 
 *        resource
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philip Levis
 * @author Eric B. Decker (cire831@gmail.com)
 *
 * WARNING: This Arbiter differs from the main TinyOS trunk Arbiter!.....   It
 * has the following features/bug fixes:
 *
 * ResourceRequested can be used to allow a holder of a resource to release
 * and request upon an incoming request from another client.
 *
 * The previous arbiter (if no other resources queued up) would always immediately
 * grant to the original holder (ie. the new requester would be starved).   And other
 * strange, out of order behaviour.
 *
 * The following is the sequence we are talking about:
 *
 *  Client 1:                Client 2:
 *  Holding resource
 *                           new request comes up
 *  Sees ResourceRequested
 *      releases (this should let the new resource (or any other queued client) get the resource)
 *      requests
 *                           client 2 gains control.
 *
 * There does need to be a mechanism to let a holder of the resource to check to see
 * if (and possibly how many) other clients are waiting for the resource.  There are
 * cases where using the event (ResourceRequested) doesn't work because the clients
 * have already posted their requests prior to the eventual resource holder gaining
 * control.   IT IS VERY EASY TO HANG THE ARBITER BECAUSE OF MISSED EVENTS.  Use
 * Request/Release at your own risk.
 *
 *
 * Protection has been put in to insure that a given client can not end up with
 * multiple requests queued up.   This would give the client an unfair advantage
 * and also would occur non-uniformly (depends on the sequence of execution).   This
 * problem could occur because while the Queueing mechanism does protect against multiple
 * instances of the id in the queue, there is also the reqResId cell which is effectively
 * the head of the queue.   This must also be properly handled to prevent a client from
 * getting into the queue multiple times.
 *
 *
 * Provisions have been made to support DefaultOwners actually doing something with the
 * hardware vs. just handling power.  PREGRANT helps with this.  Also the resId being
 * default_owner_id indicates that h/w events should be steered to the DefaultOwner.
 */

generic module ArbiterP(uint8_t default_owner_id) @safe() {
  provides {
    interface Resource[uint8_t id];
    interface ResourceRequested[uint8_t id];
    interface ResourceDefaultOwner;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceDefaultOwnerInfo;
    interface ResourceConfigure[uint8_t id];
    interface ResourceQueue as Queue;
    interface Leds;
#ifdef TRACE_RESOURCE
    interface Trace;
#endif
  }
}
implementation {

  /*
   * States:
   *
   * DEF_OWNED: (formely CONTROLLED), indicates that the DefaultOwner of the
   * resource has control.   Typically this will power down the resource, but can
   * also be used to hook a default driver that runs when ever othe clients are
   * not used the resource.
   *
   * PREGRANT denotes the resource state where a client has requested but the default
   * owner still owns, vs GRANTING where the default owner has released the resource
   * and will no longer receive resource event (such as data delivery).  GRANTING vs.
   * PREGRANT means the client will definitely be owning the resource soon.  This was
   * needed because of the DefaultOwner changes, where a DefaultOwner can really own
   * the hardware rather than just handling power state.
   *
   * GRANTING: the resource ownership is in the process of switching to a new owner.
   *
   * IMM_GRANTING: same as GRANTING but indicates an immediate grant (from an immediate
   * request).
   *
   * BUSY: the resource is owned by the client indicated in resId.
   *
   *
   * state RES_DEF_OWNED means the default owner owns the resource rather than any
   * client.  Its value needs to be 0 so that when uninitilized memory (bss) is
   * hit, state gets set to RES_DEF_OWNED.
   */

  typedef enum {RES_DEF_OWNED = 0, RES_PREGRANT, RES_GRANTING,
		RES_IMM_GRANTING, RES_BUSY}
    arb_state_t;

  enum {default_owner_id = default_owner_id};
  enum {NO_RES = 0xFF};
  enum {arbiter_id = unique("arbiter_id")};

  uint8_t state;			/* init'd to 0, RES_DEF_OWNED */
  norace uint8_t resId = default_owner_id;
  norace uint8_t reqResId = NO_RES;
  
  task void grantedTask();
  
  async command error_t Resource.request[uint8_t id]() {
    error_t rval;

    /*
     * make sure that we respect queue order, determined by the queuing discipline.
     */
#ifdef TRACE_RESOURCE
    call Trace.trace((arbiter_id << 8) | T_REQ, id, resId);
#endif
    atomic {
      /*
       * Queue.enqueue should check for the id already being in the list.
       * I don't think we want to have multiple instances of any id in the list
       * of folks waiting for the arbiter (multiple requests for the same client?)
       *
       * We also need to check to see if this client is already waiting for the
       * resource (ie. it is the next one to get it, reqResId).
       */
      if (reqResId == id)		/* already waiting for the resource. */
	return EBUSY;
      if ((rval = call Queue.enqueue(id)))
	return rval;			/* failed */
    }

    signal ResourceRequested.requested[resId]();

    /*
     * ResourceRequested.requested yanks on the current owner so that it may if desired
     * take into account that others want the resource.   As a consequence, requested may
     * change state of the arbiter.
     */

    atomic {
      /*
       * if the resource owned by a client or will be then the current
       * request just gets queued.   In other words, we are done at this point.
       *       * This is also the most likely case, so bailing early is good. */
      if (state != RES_DEF_OWNED)
	return SUCCESS;

      /*
       * Default owner has the resource, this client will be next once
       * the def_owner releases.  Change state to PREGRANT, set reqResId,
       * and tell the def_owner that the resource has been requested.
       */
      state = RES_PREGRANT;
      reqResId = call Queue.dequeue();
    }
    signal ResourceDefaultOwner.requested();
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest[uint8_t id]() {
    signal ResourceRequested.immediateRequested[resId]();
    atomic {
      /*
       * Make sure that the default owner has it.  Otherwise some other
       * client owns the resource and immediateRequested has to fail.
       */
      if (state != RES_DEF_OWNED)
	return FAIL;
      state = RES_IMM_GRANTING;
      reqResId = id;
    }
    signal ResourceDefaultOwner.immediateRequested();
    if(resId == id) {
      call ResourceConfigure.configure[resId]();
      return SUCCESS;
    }

    /*
     * We returned from immediateRequested and the requester
     * still doesn't own the resource.   The DefaultOwner has
     * decided to keep it?  So force back to DEF_OWNED.
     */
    atomic state = RES_DEF_OWNED;
    return FAIL;
  }
  
  async command error_t Resource.release[uint8_t id]() {
#ifdef TRACE_RESOURCE
    call Trace.trace((arbiter_id << 8) | T_REL, id, resId);
#endif
    atomic {
      if(state == RES_BUSY && resId == id) {
        if(call Queue.isEmpty()) {
	  /*
	   * queue empty, no more client requests, give back to the
	   * default owner.
	   */
          resId = default_owner_id;
          state = RES_DEF_OWNED;
          call ResourceConfigure.unconfigure[id]();
          signal ResourceDefaultOwner.granted();
        } else {
	  /*
	   * queue not empty, take next client from the queue
	   * and give the resource to them.  Go immediately to
	   * GRANTING, which says the default owner doesn't
	   * need to release, already released.
	   */
          reqResId = call Queue.dequeue();
          resId = NO_RES;
          state = RES_GRANTING;
          post grantedTask();
          call ResourceConfigure.unconfigure[id]();
        }
        return SUCCESS;
      }
    }
    return FAIL;
  }

  async command error_t ResourceDefaultOwner.release() {
    atomic {
      if(resId == default_owner_id) {
        if(state == RES_GRANTING || state == RES_PREGRANT) {
	  state = RES_GRANTING;
          post grantedTask();
          return SUCCESS;
        }
        else if(state == RES_IMM_GRANTING) {
          resId = reqResId;
	  reqResId = NO_RES;
          state = RES_BUSY;
          return SUCCESS;
        }
      }
    }
    return FAIL;
  }
    
  /**
    Check if the Resource is currently in use

    DefaultOwner maybe busy using the resourse.  Need extra level of check.
  */    
  async command bool ArbiterInfo.inUse() {
    atomic {
      if (state == RES_DEF_OWNED)
	return call ResourceDefaultOwnerInfo.inUse();
      return TRUE;
    }
  }

  /**
   * Returns the current user of the Resource.
   *
   * formerly checked state, but now relies solely on current
   * owner, ie. resId.   Just return resId.   If the
   * default owner owns the resource then the resId will
   * be one higher than the max client id.
   *
   * This was originally part of ResourceDefaultOwner
   * (SerialDemux) changes.   It is needed if a DefaultOwner
   * actually needs to do something with the hardware.  Ie.
   * interrupts need to be steered to the ResourceDefaultOwner
   * demultiplexer.   In which case the client id (resId) is
   * used to do the signal and needs to be a real number and not
   * 0xff (NO_RES).
   */
  async command uint8_t ArbiterInfo.userId() {
    return resId;
  }

   /**
   * Is this client the owner of the resource.
   */      
  async command bool Resource.isOwner[uint8_t id]() {
    atomic return (resId == id && state == RES_BUSY);
  }

  async command bool ResourceDefaultOwner.isOwner() {
    atomic return (state == RES_DEF_OWNED || state == RES_PREGRANT);
  }

  task void grantedTask() {
    atomic {
      resId = reqResId;
      reqResId = NO_RES;
      state = RES_BUSY;
    }
#ifdef TRACE_RESOURCE
    call Trace.trace((arbiter_id << 8) | T_GRANT, resId, 0);
#endif
    call ResourceConfigure.configure[resId]();
    signal Resource.granted[resId]();
  }

// Default event/command handlers for all of the other
// potential users/providers of the parameterized interfaces
// that have not been connected to.

  default event void Resource.granted[uint8_t id]() { }
  default async event void ResourceRequested.requested[uint8_t id]() { }
  default async event void ResourceRequested.immediateRequested[uint8_t id]() { }
  default async event void ResourceDefaultOwner.granted() { }
  default async command void ResourceConfigure.configure[uint8_t id]() { }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() { }

  default async event void ResourceDefaultOwner.requested() {
    call ResourceDefaultOwner.release();
  }

  default async event void ResourceDefaultOwner.immediateRequested() {
    call ResourceDefaultOwner.release();
  }

  default async command bool ResourceDefaultOwnerInfo.inUse() {
    return FALSE;
  }
}
