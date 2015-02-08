-module(vhs_hackney).
-include_lib("eunit/include/eunit.hrl").
-export([configure/1,
         configure/0,
         block_end/0,
         block_start/1]).

configure(_Opts) ->
    try meck:new(hackney, [passthrough])
    catch
        error:_ -> ok
    end.

configure() ->
    configure([]).

block_start(AllCalls) ->
    %% Unsure whether this code is really specific for hackney or could be lifted
    %% into the main vhs module
    MockBehavior = fun(Args) ->
        case proplists:get_value(Args, AllCalls) of
            undefined ->
                Response = meck:passthrough(Args),
                {State, StatusCode, RespHeaders, ClientRef} = Response,
                Body = case State of
                    ok -> {ok, Body2} = hackney:body(ClientRef), Body2;
                    _  -> undefined
                end,
                Call = {Args, {State, StatusCode, RespHeaders, erlang:ref_to_list(ClientRef), Body}},
                vhs:record(Call),
                mock_body(ClientRef, Body),
                Response;
            Response ->
                {State, StatusCode, RespHeaders, ClientRef, Body} = Response,
                mock_body(ClientRef, Body),
                {State, StatusCode, RespHeaders, ClientRef}
        end
    end,
    mock_hackney(hackney, request, MockBehavior).

block_end() ->
    meck:unload(hackney).

%% HACK
mock_hackney(Module, FuncName, MockBehavior) ->
    meck:expect(Module, FuncName, fun(A1,A2) -> MockBehavior([A1,A2]) end),
    meck:expect(Module, FuncName, fun(A1,A2,A3) -> MockBehavior([A1,A2,A3]) end),
    meck:expect(Module, FuncName, fun(A1,A2,A3,A4) -> MockBehavior([A1,A2,A3,A4]) end),
    meck:expect(Module, FuncName, fun(A1,A2,A3,A4,A5) -> MockBehavior([A1,A2,A3,A4,A5]) end),
    ok.

mock_body(ClientRef, Body) ->
  meck:expect(hackney, body, fun(Ref) ->
    case Ref of
        ClientRef -> {ok, Body};
        _         -> meck:passthrough([Ref])
    end
  end).
