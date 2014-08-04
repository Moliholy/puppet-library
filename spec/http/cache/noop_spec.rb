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

module PuppetLibrary::Http::Cache
    describe NoOp do
        let(:cache) { NoOp.new }

        describe "#get" do
            it "never caches the content" do
                name = cache.get("name") { "joe" }
                name = cache.get("name") { "james" }
                expect(name).to eq "james"
            end
        end

        describe "#clear" do
            it "does nothing" do
                cache.clear
            end
        end
    end
end
