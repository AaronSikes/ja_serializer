defmodule JaSerializer.Relationship do
  @moduledoc false

  @doc false
  def default_function(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      def unquote(name)(model, _conn) do
        JaSerializer.Relationship.get_data(model, unquote(name), unquote(opts))
      end
      defoverridable [{name, 2}]
    end
  end

  if Code.ensure_loaded?(Ecto) do
    require Logger

    # If ecto is loaded we try to load relationships appropriately
    def get_data(model, name, opts) do
      relationship = (opts[:field] || name)
      model
      |> Map.get(relationship)
      |> case do
        %Ecto.Association.NotLoaded{} ->
          Logger.debug("Consider preloading #{relationship} to improve performance")
          Ecto.Model.assoc(model, relationship) |> find_repo(opts).all
        other -> other
      end
    end

    defmodule UnknownRepoError do
      defexception [:message]

      def exception(_val) do
        msg = """
        JaSerializer was unable to fetch your relationship data.

        JaSerializer can fetch your relationship for you if provided the `:repo`
        key to the relationship definition or globally via the application config.
        """
        %UnknownRepoError{message: msg}
      end
    end

    defp find_repo(%{repo: repo}), do: repo
    defp find_repo(_) do
      case Application.get_env(:ja_serializer, :repo) do
        nil -> raise UnknownRepoError
        repo -> repo
      end
    end

  else

    # If ecto is not loaded we just return the struct field.
    def get_data(model, name, opts) do
      Map.get(model, (opts[:field] || name))
    end

  end
end
