=begin
Written by Irvin.
Distributed under the terms of the GNU General Public License v2.
=end

require 'rubygems'
require 'zip'
require 'yaml'
require 'json'
require 'fileutils'
require 'perfect_toml'
require 'http'
require 'http-cookie'
require 'nokogiri'

class Config

# Constructor
        def initialize(configPath = "./config/", modFile = "mods.yml", configFile = "config.toml", serverFile = "server.toml")
           @configFile = configFile
           @configPath = configPath
           @modFile = modFile
           @serverFile = serverFile

           if (! Dir.exist? @configPath)
               Dir.mkdir(@configPath)
           end
           if (! File.exist? @configPath + @configFile)
               PerfectTOML.save_file(@configPath + @configFile, { URL: "", email: "", password: "" })
           end
        end

        def getConfig()
            config = PerfectTOML.load_file(@configPath + @configFile)
        end

        def getMods()
            mods = YAML.load_file(@configPath + @modFile)
        end

        def getConfigPath()
            @configPath
        end

        def getModPath()
            @modFile
        end

        def getServerPath()
            @serverFile
        end

        def writeServer(server)
            PerfectTOML.save_file(@configPath + @serverFile, server)
        end
end

class Net
    def initialize(config)
        @cookies = jar = HTTP::CookieJar.new
        @config = config
        @configPath = config.getConfigPath()
        @serverF
        @url = config.getConfig()["URL"]
        @email = config.getConfig()["email"]
        @password = config.getConfig()["password"]
        cookies = config.getConfigPath() + "cookies.txt"
        @cookies.load(cookies) if File.exist?(cookies)
        @_token = ""

        puts getPage(@url + "/dashboard").status

        case(getPage(@url + "/dashboard").status)
        when 200
            puts "INFO: logged in."
        when 302
            puts "INFO: logged out, logging you in."
            login()
        when 404
            puts "ERROR: cannot find the dashboard path!"
            return nil
        end
        @cookies.save(cookies)
    end

    def login()
        url = @url + "/login"
        response = getPage(url)
        token = getToken(response)
        postPage(url, :form => {
            :_token   => token,
            :email    => @email,
            :password => @password
        })
    end

    def parseCookies(response)
        #puts @cookies
        response.headers["Set-Cookie"].each { |value| @cookies.parse(value, response.uri) } if(! response.headers["Set-Cookie"].nil?)
    end

    def getPage(url)
        response = HTTP.cookies(@cookies).get(url)
        parseCookies(response)
        response
    end

    def getToken(response)
        html = Nokogiri::HTML(response.body.to_s)
        @_token = html.xpath("//form/input")[0].attribute_nodes[2].value
    end

    def postPage(url, form, headers={})
        puts form
        response = HTTP.cookies(@cookies).headers(headers).post(url, form)
        puts "POST-" + response
        parseCookies(response)
        response
    end

    def getMod(name)
        sleep 0.1
        response = getPage(@url + "/api/mod/" + name)
        if(response.status == 404)
            puts "#{name} not found"
            false
        elsif(response.status == 200)
            puts "#{name}: was successfully found"
            mod = JSON.parse(response.body)
        else
            puts "else condition, #{response.status}"
        end
    end

    def getModId(mod)
        if(mod)
            mod["id"]
        else
            false
        end
    end

    def getModVersions(mod)
        if(mod)
            mod["versions"]
        else
            false
        end
    end

    def versionCheck(mod, version)
        mod["versions"].exists(version)
    end

    def addMod(name)
        url = @url + "/mod/create"
        response = getPage(url)
        @_token = getToken(response)
        response = postPage(url, :form => {
            :_token   => @_token,
            :pretty_name => name,
            :name => name,
            :author => "",
            :description => "",
            :link => ""
        })
        if(response["location"])
            response["location"].split('/')[-1]
        else
            false
        end
    end

    def addMods()
        serverFile = PerfectTOML.load_file(@config.getConfigPath() + @config.getServerPath())
        serverFile.each do | name, value |
            if(!value["serverModId"])
                puts "created: " + name
                modId=addMod(name)
                if(modId)
                    serverFile[name]["serverModId"] = modId
                end
            end
        end
        @config.writeServer(serverFile)
    end

    def addVersion(id, version)
        modPageUrl = @url + "/mod/view/#{id}"
        response = getPage(modPageUrl)
        @_token = getToken(response)
        url = @url + "/mod/add-version"
        response = postPage(url, {:form => {
            :_token   => @_token,
            :'mod-id' => id,
            :'add-version' => version,
            :'add-md5' => ""
        }}, :'X-CSRF-TOKEN' => @_token,
            :'X-Requested-With' => 'XMLHttpRequest',
            :Origin => modPageUrl)
        json = JSON.parse(response.body)
        puts json
        if(json["status"] == "success")
            true
        else
            puts "failed: #{json["reason"]}"
            false
        end
    end

    def addVersions()
        serverFile = PerfectTOML.load_file(@config.getConfigPath() + @config.getServerPath())
        puts serverFile
        serverFile.each do | name, value |
            if(value["serverModId"] && !(value["serverModVersions"]))
               puts "adding version: " + name + value["version"]
               modId=addVersion(value["serverModId"], value["version"])
               if(modId)
                    serverFile[name]["serverModVersions"] = value["version"]
               end
            elsif(value["serverModId"] && (!(value["serverModVersions"].include?(value["version"]))) )
                puts "adding version: " + name + value["version"]
                modId=addVersion(value["serverModId"], value["version"])
                if(modId)
                    serverFile[name]["serverModVersions"] = value["serverModVersions"].append(value["version"])
                end
            end
        end
        puts serverFile
        @config.writeServer(serverFile)
    end

end

class Work
    def initialize(config, session)
        @config = config
        @session = session
        @configPath = config.getConfigPath
        @modFile = config.getModPath
    end
# Create an archive (.zip) that includes mods folder and mod itself.
    def populate_server()
        configHash = YAML.load_file( @configPath + @modFile )

        entry = {}

        configHash.each do | key, value |
            mod = @session.getMod(key)
            modId = @session.getModId(mod)
            modVersions = @session.getModVersions(mod)
            entry[key] = {
                        "version" => value["version"],
                        "filename" => value["filename"],
                        "serverModId" => modId,
                        "serverModVersions" => modVersions,
                        "newMod" => (!modId) ? true : false
            }
        end
        @config.writeServer(entry)
    end

end

config = Config.new()
session = Net.new(config)
work = Work.new(config, session)
#session.addVersion("1", "1.2")
#session.addMods()
#session.addMod("test4")
work.populate_server()
#session.addVersions
#session.addMods()
