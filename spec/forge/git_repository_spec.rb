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

module PuppetLibrary::Forge
    describe GitRepository do
        @@repo_path = Tempdir.create("git-repo")
        @@versions = [ "0.9.0", "1.0.0-rc1", "1.0.0" ]
        @@tags = @@versions.map {|version| "v#{version}"} + [ "xxx" ]

        before :all do
            def git(command)
                git_command = "git --git-dir=#{@@repo_path}/.git --work-tree=#{@@repo_path} #{command}"
                `#{git_command}`
                unless $?.success?
                    raise "Failed to run command: \"#{git_command}\""
                end
            end

            git "init"
            git "config user.name tester"
            git "config user.email tester@example.com"
            @@versions.zip(@@tags).each do |(version, tag)|
                File.open(File.join(@@repo_path, "Modulefile"), "w") do |modulefile|
                    modulefile.write <<-MODULEFILE
                    name 'puppetlabs-apache'
                    version '#{version}'
                    author 'puppetlabs'
                    MODULEFILE
                end
                git "add ."
                git "commit --message='Version #{version}'"
                git "tag #{tag}"
            end
        end

        after :all do
            rm_rf @@repo_path
        end

        let :forge do
            cache_path = PuppetLibrary::Util::TempDir.create("git-repo-cache")
            git = PuppetLibrary::Util::Git.new(@@repo_path, cache_path)
            GitRepository.new(git, /[0-9.]+/)
        end

        after do
            forge.clear_cache
        end

        describe "#configure" do
            it "exposes a configuration API" do
                forge = GitRepository.configure do
                    source @@repo_path
                    include_tags /v123/
                end
                expect(forge.instance_eval "@version_tag_regex").to eq /v123/
            end
        end

        describe "#prime" do
            it "creates the repo cache" do
                git = double('git')
                forge = GitRepository.new(git, //)

                expect(git).to receive(:update_cache!)

                forge.prime
            end
        end

        describe "#clear_cache" do
            it "deletes the repo cache" do
                git = double('git')
                forge = GitRepository.new(git, //)

                expect(git).to receive(:clear_cache!)

                forge.clear_cache
            end
        end

        describe "#get_module" do
            context "when the requested author is different from the configured author" do
                it "returns nil" do
                    buffer = forge.get_module("dodgybrothers", "apache", "1.0.0")
                    expect(buffer).to be_nil
                end
            end

            context "when the requested module name is different from the configured name" do
                it "returns nil" do
                    buffer = forge.get_module("puppetlabs", "stdlib", "1.0.0")
                    expect(buffer).to be_nil
                end
            end

            context "when the tag for the requested version doesn't exist" do
                it "returns nil" do
                    buffer = forge.get_module("puppetlabs", "apache", "9.9.9")
                    expect(buffer).to be_nil
                end
            end

            context "when the module is requested" do
                it "returns an archive of the module" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")
                    expect(buffer).to be_tgz_with "puppetlabs-apache-1.0.0/Modulefile", /version '1.0.0'/
                end
                it "generates the metadata file and includes it in the archive" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")
                    expect(buffer).to be_tgz_with "puppetlabs-apache-1.0.0/metadata.json", /"version":"1.0.0"/
                end
            end
        end

        describe "#get_metadata" do
            context "when the requested author is different from the configured author" do
                it "returns nil" do
                    metadata = forge.get_metadata("dodgybrothers", "apache")
                    expect(metadata).to be_empty
                end
            end

            context "when the requested module name is different from the configured name" do
                it "returns an empty array" do
                    metadata = forge.get_metadata("puppetlabs", "stdlib")
                    expect(metadata).to be_empty
                end
            end

            context "when the module is requested" do
                it "generates the metadata for the each version" do
                    metadata = forge.get_metadata("puppetlabs", "apache")
                    expect(metadata).to have(3).versions
                    expect(metadata.first["name"]).to eq "puppetlabs-apache"
                    expect(metadata.first["version"]).to eq "0.9.0"
                end
            end
        end

        describe "#get_all_metadata" do
            it "generates the metadata for the each version" do
                metadata = forge.get_all_metadata
                expect(metadata).to have(3).versions
                expect(metadata.first["name"]).to eq "puppetlabs-apache"
                expect(metadata.first["version"]).to eq "0.9.0"
            end
        end
    end
end
