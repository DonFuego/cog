defmodule Cog.Commands.Permission do
  use Cog.Command.GenCommand.Base, bundle: Cog.Util.Misc.embedded_bundle
  require Cog.Commands.Helpers, as: Helpers
  alias Cog.Commands.Permission.{Grant, List, Revoke}

  Helpers.usage(:root)

  @description "Manage authorization permissions"

  @arguments "[subcommand]"

  @subcommands %{
    "list" => "List all permissions (default)",
    "info <permission>" => "Get detailed information about a specific permission",
    "create site:<permission>" => "Create a new site permission",
    "delete site:<permission>" => "Delete an existing site permission",
    "grant <permission> <role>" => "Grant a permission to a role",
    "revoke <permission> <role>" => "Revoke a permission from a group"
  }

  permission "manage_permissions"
  permission "manage_roles"

  # first rule is for default list scenario
  rule "when command is #{Cog.Util.Misc.embedded_bundle}:permission must have #{Cog.Util.Misc.embedded_bundle}:manage_permissions"

  rule "when command is #{Cog.Util.Misc.embedded_bundle}:permission with arg[0] == grant must have #{Cog.Util.Misc.embedded_bundle}:manage_roles"
  rule "when command is #{Cog.Util.Misc.embedded_bundle}:permission with arg[0] == revoke must have #{Cog.Util.Misc.embedded_bundle}:manage_roles"

  def handle_message(req, state) do
    {subcommand, args} = Helpers.get_subcommand(req.args)

    result = case subcommand do
               "grant"  -> Grant.grant(req, args)
               "revoke" -> Revoke.revoke(req, args)
               nil ->
                 if Helpers.flag?(req.options, "help") do
                   show_usage
                 else
                   List.handle_message(req, state)
                 end
               other ->
                 {:error, {:unknown_subcommand, other}}
             end

    case result do
      {:ok, template, data} ->
         {:reply, req.reply_to, template, data, state}
      {:ok, data} ->
        {:reply, req.reply_to, data, state}
      {:error, err} ->
        {:error, req.reply_to, error(err), state}
    end
  end

  def error(:invalid_permission),
    do: "Only permissions in the `site` namespace can be created or deleted; please specify permission as `site:<NAME>`"
  def error(:wrong_type),
    do: "Arguments must be strings"
  def error(error),
    do: Helpers.error(error)

end
