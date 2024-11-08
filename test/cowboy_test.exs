defmodule PlugLiveReload.Test.Router do
  use Plug.Router

  plug(PlugLiveReload)
  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "<html><body><h1>Plug</h1></body></html>")
  end
end

defmodule PlugLiveReload.Test.CowboyTest do
  use ExUnit.Case, async: true
  alias PlugLiveReload.Test.Router

  setup context do
    port = 4067

    children = [
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: port, dispatch: dispatch()]}
    ]

    supervisor_spec = %{
      id: context.test,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 5000
    }

    {:ok, supervisor} = start_supervised(supervisor_spec)
    # Get the server process
    [{_, server, _, _}] = Supervisor.which_children(supervisor)
    # Return both the base URL and server reference
    [base_url: "http://localhost:#{port}", server: server]
  end

  test "test before reloading", %{base_url: base_url} do
    body = Req.get!(base_url, retry: false).body

    assert body ==
             ~s(<html><body><h1>Plug</h1><iframe src="/plug_live_reload/frame" hidden height="0" width="0"></iframe></body></html>)
  end

  defp dispatch(),
    do: [
      {:_,
       [
         {"/plug_live_reload/socket", PlugLiveReload.Socket, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
end
