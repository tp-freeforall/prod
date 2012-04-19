/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Component that stores the node's active message address and group ID.
 * The L-node provides its own because our AM address includes the AM group bits.
 * It also provides an additional NetMask interface.
 */
module ActiveMessageAddressC	{
	provides {
		interface ActiveMessageAddress;
		interface NetMask;
	}
}

implementation {
	
	// this is set to TOS_NODE_ID by tos-set-symbols, so we'll add the group bits on demand
	am_addr_t addr = DEFINED_TOS_AM_ADDRESS;
	am_addr_t group = DEFINED_TOS_AM_GROUP;
	am_addr_t netmask = DEFINED_AM_NETWORK_MASK;
	
	async command am_addr_t ActiveMessageAddress.amAddress() {
		atomic return group | addr;
	}
	
	async command void ActiveMessageAddress.setAddress(am_group_t myGroup, am_addr_t myAddr) {
		atomic {
			addr = myAddr;
			group = myGroup;
		}
		
		signal ActiveMessageAddress.changed();
	}
	
	async command am_group_t ActiveMessageAddress.amGroup() {
		atomic return group;
	}
	
	async command void NetMask.setNetMask(am_netmask_t myNetmask) {
		atomic netmask = myNetmask;
		signal ActiveMessageAddress.changed();
	}
	
	async command am_netmask_t NetMask.netMask() {
		atomic return netmask;
	}

	default async event void ActiveMessageAddress.changed() {}
	
}
