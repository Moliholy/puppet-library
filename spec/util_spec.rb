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

require 'spec_helper'

describe 'util' do
    describe Array do
        describe "#unique_by" do
            it "behaves like #uniq with a block, but works with Ruby < 1.9" do
                son = { "name" => "john", "age" => 10 }
                dad = { "name" => "john", "age" => 40 }
                mom = { "name" => "jane", "age" => 40 }

                family = [son, dad, mom]
                expect(family.unique_by {|p| p["name"]}).to eq [son, mom]
            end
        end

        describe "#version_sort" do
            it "sorts according to version numbers" do
                expect(["2.0.0", "1.10.0", "1.2.0"].version_sort).to eq ["1.2.0", "1.10.0", "2.0.0"]
            end

            it "copes with odd versions" do
                # this is supported in most Rubygems versions, but gives 'ArgumentError: Malformed version number string 1.10.0-rc1" in Rubygems 2.0.3
                expect(["1.10.0", "1.10.0-rc1", "1.2.0"].version_sort).to eq ["1.2.0", "1.10.0-rc1", "1.10.0"]
            end
        end
    end
end
