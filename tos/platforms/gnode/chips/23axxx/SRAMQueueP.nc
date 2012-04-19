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

generic module SRAMQueueP(typedef queue_t, uint16_t QUEUE_SIZE, uint16_t OFFSET) {
	provides {
		interface BigQueue<queue_t>;
	}
	
	uses {
		interface SRAM;
	}
}

implementation {

	uint16_t head = 0;
	uint16_t tail = 0;
	uint16_t size = 0;
	
	uint16_t addr(uint16_t idx) {
		return OFFSET + idx * sizeof(queue_t);
	}
	
	queue_t read(uint16_t idx) {
		queue_t item;
		call SRAM.read(addr(idx), sizeof(queue_t), &item);
		return item;
	}
	
	void write(uint16_t idx, queue_t item) {
		call SRAM.write(addr(idx), sizeof(queue_t), &item);
	}
	
	command bool BigQueue.empty() {
		return size == 0;
	}

	command uint16_t BigQueue.size() {
		return size;
	}

	command uint16_t BigQueue.maxSize() {
		return QUEUE_SIZE;
	}

	command queue_t BigQueue.head() {
		return read(head);
	}
	
	command queue_t BigQueue.dequeue() {
		queue_t t = call BigQueue.head();
		if (!call BigQueue.empty()) {
			head++;
			head %= QUEUE_SIZE;
			size--;
		}

		return t;
	}

	command error_t BigQueue.enqueue(queue_t newVal) {
		if (call BigQueue.size() < call BigQueue.maxSize()) {
			write(tail, newVal);
			tail++;
			tail %= QUEUE_SIZE;
			size++;
			return SUCCESS;
		}
		else {
			return FAIL;
		}
	}
	
	command queue_t BigQueue.element(uint16_t idx) {
		idx += head;
		idx %= QUEUE_SIZE;
		return read(idx);
	}	

}
