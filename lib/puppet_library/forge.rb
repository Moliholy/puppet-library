# -*- encoding: utf-8 -*-
# Puppet Library
# Copyright (C) 2014 drrb
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Array
    def deep_merge
        inject({}) do |merged, map|
            merged.deep_merge(map)
        end
    end
end

class Hash
    def deep_merge(other)
        merge(other) do |key, old_val, new_val|
            if old_val.instance_of? Array
                old_val + new_val
            else
                new_val
            end
        end
    end
end

module PuppetLibrary
    class ModuleNotFound < Exception
    end

    class Forge
        class Config
            def initialize(module_repo)
                @module_repo = module_repo
            end

            def module_repo(repo)
                @module_repo.add_repo repo
            end
        end

        def self.configure(&config_block)
            module_repo = ModuleRepo::Multi.new
            yield(Config.new(module_repo))
            Forge.new(module_repo)
        end

        def initialize(module_repo)
            @repo = module_repo
        end

        def get_module_metadata(author, name)
            modules = get_metadata(author, name)

            raise ModuleNotFound if modules.empty?

            module_infos = modules.map { |m| m.to_info }
            module_infos.deep_merge
        end

        def get_module_metadata_with_dependencies(author, name)
            full_name = "#{author}/#{name}"

            collect_dependencies_versions(full_name).tap do |versions|
                raise ModuleNotFound if versions[full_name].empty?
            end
        end

        def collect_dependencies_versions(module_full_name, metadata = {})
            author, module_name = module_full_name.split "/"
            module_versions = get_metadata(author, module_name)
            metadata[module_full_name] = module_versions.map {|v| v.to_version }

            dependencies = module_versions.map {|v| v.dependency_names }.flatten
            dependencies.each do |dependency|
                collect_dependencies_versions(dependency, metadata) unless metadata.include? dependency
            end
            return metadata
        end

        def get_module_buffer(author, name, version)
            @repo.get_module(author, name, version) or raise ModuleNotFound
        end

        def get_metadata(author, module_name)
            @repo.get_metadata(author, module_name).map {|metadata| ModuleMetadata.new(metadata)}
        end
    end
end
