-module (vhs_hackney_test).
-include_lib ("etest/include/etest.hrl").
-include_lib("eunit/include/eunit.hrl").
-compile (export_all).

%% vhs:configure should work for hackney
 % test_configure_with_hackney_adapter() ->
 %   ?assert_no_throw(adapter_not_supported,
 %                    vhs:configure(hackney, [])).

%% vhs:use_cassete should save all the request-responses into the tape file
test_recording_a_call_with_hackney_adapter() ->
    hackney:start(),
    vhs:configure(hackney, []),
    AssertHeader = fun(Key, Headers) ->
        ?assert(proplists:is_defined(Key, Headers))
    end,
    vhs:use_cassette(iana_domain_hackney_test, fun() ->
        {ok, StatusCode, RespHeaders, ClientRef}     = hackney:get("http://localhost:8000/200.html", [], <<>>, []),
        ServerState                                  = vhs:server_state(),
        [{Request, Response}]                        = ServerState,
        ExpectedBody                                 = <<"<!doctype html>\n<html>\n\t<head><title>Document delivered by dummy server</title></head>\n\t<body>Hello World!</body>\n</html>\n">>,
        {ok, 200, Headers, _ClientRef, ExpectedBody} = Response,
        ExpectedRequest                              = [get,"http://localhost:8000/200.html",[],<<>>,[]],
        ExpectedHeaders                              = [<<"Server">>, <<"Date">>, <<"Content-Length">>, <<"Content-Type">>],
        ?assert_equal(Request, ExpectedRequest),
        ?assert_equal({ok, ExpectedBody}, hackney:body(ClientRef)),
        [ AssertHeader(Key, Headers) || Key <- ExpectedHeaders ]
    end),

    %% Cleans the state of the server after the block is executed
    ?assert_equal([], vhs:server_state()),

    %% It should have the nice side-effect of creating a new file
    {ok, [StoredCalls]} = file:consult("/tmp/iana_domain_hackney_test"),

    %% The number of stored calls should correspond to the calls done inside of the block.
    ?assert_equal(1, length(StoredCalls)).

%% vhs:use_cassete should save all the request-responses into the tape file
% test_invariants_when_no_call_is_performed_hackney() ->
%   ibrowse:start(),
%   vhs:configure(hackney, []),
%   vhs:use_cassette(another_call,
%                    fun() ->
%                        ?assert_equal([], vhs:server_state())
%                    end),
%
%   %% Cleans the state of the server after the block is executed
%   ?assert_equal([], vhs:server_state()),
%
%   %% It should have the nice side-effect of creating a new file
%   {ok, [[]]} = file:consult("/tmp/another_call"),
%   ok.
