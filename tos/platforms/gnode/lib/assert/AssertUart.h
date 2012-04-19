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

#ifndef ASSERTUART_H
#define ASSERTUART_H

// preprocessor magic to get __LINE__ as a string, from
// http://www.decompile.com/cpp/faq/file_and_line_error_string.htm
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

// Long paths in __FILE__ file names may use excessive amounts
// of memory (either ROM or both ROM and RAM, depending on your compiler)
// so this define allows you to switch file names on and off.
#ifdef ASSERT_UART_EXCLUDE_FILE_NAME
#define SOURCE_LOCATION "line " TOSTRING(__LINE__)
#else
#define SOURCE_LOCATION __FILE__ ":" TOSTRING(__LINE__)
#endif

#define assert(condition, output) doAssert((condition), (output), #condition, #output, SOURCE_LOCATION)
#define assertNot(condition, output) doAssertNot((condition), (output), #condition " != FALSE", #output, SOURCE_LOCATION)
#define assertSuccess(err, output) doAssertSuccess((err), (output), #err " != SUCCESS", #output, SOURCE_LOCATION)
#define assertEquals(a, b, output) doAssertEquals((a), (b), (output), #a, #b, #output, SOURCE_LOCATION)

#endif
