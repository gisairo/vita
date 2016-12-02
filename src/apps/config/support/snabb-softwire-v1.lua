-- Use of this source code is governed by the Apache 2.0 license; see COPYING.
module(..., package.seeall)
local ffi = require('ffi')
local app = require('core.app')
local data = require('lib.yang.data')
local yang = require('lib.yang.yang')
local path_mod = require('lib.yang.path')
local generic = require('apps.config.support').generic_schema_config_support

local function add_softwire_entry_actions(app_graph, entries)
   assert(app_graph.apps['lwaftr'])
   local ret = {}
   for entry in entries:iterate() do
      local blob = entries.entry_type()
      ffi.copy(blob, entry, ffi.sizeof(blob))
      local args = {'lwaftr', 'add_softwire_entry', blob}
      table.insert(ret, {'call_app_method_with_blob', args})
   end
   return ret
end

local softwire_grammar
local function get_softwire_grammar()
   if not softwire_grammar then
      local schema = yang.load_schema_by_name('snabb-softwire-v1')
      local grammar = data.data_grammar_from_schema(schema)
      softwire_grammar =
         assert(grammar.members['softwire-config'].
                   members['binding-table'].members['softwire'])
   end
   return softwire_grammar
end

local function remove_softwire_entry_actions(app_graph, path)
   assert(app_graph.apps['lwaftr'])
   path = path_mod.parse_path(path)
   local grammar = get_softwire_grammar()
   local key = path_mod.prepare_table_lookup(
      grammar.keys, grammar.key_ctype, path[#path].query)
   local args = {'lwaftr', 'remove_softwire_entry', key}
   return {{'call_app_method_with_blob', args}}
end

local function compute_config_actions(old_graph, new_graph, to_restart,
                                      verb, path, arg)
   if verb == 'add' and path == '/softwire-config/binding-table/softwire' then
      return add_softwire_entry_actions(new_graph, arg)
   elseif (verb == 'remove' and
           path:match('^/softwire%-config/binding%-table/softwire')) then
      return remove_softwire_entry_actions(new_graph, path)
   else
      return generic.compute_config_actions(
         old_graph, new_graph, to_restart, verb, path, arg)
   end
end

local function update_mutable_objects_embedded_in_app_initargs(
      in_place_dependencies, app_graph, schema_name, verb, path, arg)
   if verb == 'add' and path == '/softwire-config/binding-table/softwire' then
      return in_place_dependencies
   elseif (verb == 'remove' and
           path:match('^/softwire%-config/binding%-table/softwire')) then
      return in_place_dependencies
   else
      return generic.update_mutable_objects_embedded_in_app_initargs(
         in_place_dependencies, app_graph, schema_name, verb, path, arg)
   end
end

local function compute_apps_to_restart_after_configuration_update(
      schema_name, configuration, verb, path, in_place_dependencies)
   if verb == 'add' and path == '/softwire-config/binding-table/softwire' then
      return {}
   elseif (verb == 'remove' and
           path:match('^/softwire%-config/binding%-table/softwire')) then
      return {}
   else
      return generic.compute_apps_to_restart_after_configuration_update(
         schema_name, configuration, verb, path, in_place_dependencies)
   end
end

function get_config_support()
   return {
      compute_config_actions = compute_config_actions,
      update_mutable_objects_embedded_in_app_initargs =
         update_mutable_objects_embedded_in_app_initargs,
      compute_apps_to_restart_after_configuration_update =
         compute_apps_to_restart_after_configuration_update
   }
end
