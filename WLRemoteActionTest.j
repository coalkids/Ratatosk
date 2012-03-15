/*
 * WLRemoteActionTest.j
 * Ratatosk
 *
 * Created by Alexander Ljungberg on March 15th, 2012.
 * Copyright 2012, WireLoad Inc. All rights reserved.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer. Redistributions in binary
 * form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials provided
 * with the distribution. Neither the name of WireLoad Inc. nor the names
 * of its contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

@import "WLRemoteObject.j"
@import "WLRemoteLink.j"
@import "WLRemoteObjectTest.j"

var lastAction,
    lastRequest;

@implementation WLRemoteActionTest : OJTestCase
{
}

- (void)tearDown
{
    [WLRemoteObject clearInstanceCache];
}

- (void)testEncodeDecodeDelegates
{
    var testObject = [[CustomContentTypeObject alloc] initWithJson:{'id': nil, 'name': 'actionTest'}];
    [testObject ensureCreated];
    [[WLRemoteLink sharedRemoteLink] setShouldFlushActions:YES];
    // Check that the request has been specially encoded.

    [self assert:@"application/clues; charset=runes" equals:[lastRequest valueForHTTPHeaderField:@"Accept"]];
    [self assert:@"application/clues; charset=runes" equals:[lastRequest valueForHTTPHeaderField:@"Content-Type"]];
    [self assert:'{"id":null,"name":"actionTest","count":5,"other_objects":[],"pastry":null,"weasel":45}' equals:[lastRequest HTTPBody]];

    // Now simulate a response.
    var aResponse = [[CPHTTPURLResponse alloc] initWithURL:nil];
    [aResponse _setStatusCode:200];
    [lastAction connection:nil didReceiveResponse:aResponse];
    [lastAction connection:nil didReceiveData:'{"id":10,"name":"randomChange","count":5,"other_objects":[],"pastry":null}'];

    [self assert:10 equals:[testObject pk] message:@"pk field should have been updated"];
    [self assert:@"randomChange" equals:[testObject name] message:@"name field should have been updated"];
    [self assert:@"semla" equals:[testObject pastry] message:@"pastry field should be set by custom decoder"];
}

@end

@implementation CustomContentTypeObject : TestRemoteObject
{
    CPString pastry @accessors;
}


+ (CPArray)remoteProperties
{
    return [[super remoteProperties] arrayByAddingObject:['pastry']];
}

- (CPString)remoteActionContentType:(WLRemoteAction)anAction
{
    return @"application/clues; charset=runes";
}

- (CPString)remoteAction:(WLRemoteAction)anAction encodeRequestBody:(Object)aRequestBody
{
    // CPLog.error("remoteAction: " + anAction + " encodeRequestBody: " + aRequestBody);
    aRequestBody['weasel'] = 45;
    return [CPString JSONFromObject:aRequestBody];
}

- (CPString)remoteAction:(WLRemoteAction)anAction decodeResponseBody:(Object)aResponseBody
{
    var r = [aResponseBody objectFromJSON];
    r['pastry'] = 'semla';
    return r;
}

- (CPString)description
{
    return "<CustomContentTypeObject " + [self UID] + " " + [self pk] + " " + [self name] + " pastry: " + [self pastry] + ">";
}

@end

@implementation WLRemoteAction (UnitTest)

- (CPURLConnection)makeConnectionWithRequest:(CPURLRequest)aRequest
{
    // CPLog.error(self + " makeConnection: " + aRequest);
    lastAction = self;
    lastRequest = aRequest;
    // Don't actually send anything.
}

@end
