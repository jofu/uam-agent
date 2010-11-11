module ExtendPuppetUser
  def getPW
    return nil unless self.ensure == :present
    entScmd = open('|/usr/bin/getent shadow ' + self.name)
    entSout = entScmd.read()
    return entSout.split(/:/)[1]
  end
  def isLocked
    return nil unless self.ensure == :present
    pw = self.getPW
    if pw =~ /^!!.*/
      return true
    else
      return false
    end
  end
end

module MCollective
  module Agent
    class Uam<RPC::Agent
      metadata  :name         => "SimpleRPC Agent For User Management",
                :description  => "Agent To Manage Users",
                :author       => "Jonathan Furrer",
                :license      => "GPLv2",
                :version      => "1.0",
                :url          => "http://www.jofu.com/os/mcollective/agents",
                :timeout      => 180

      ["status", "lock", "add", "remove"].each do |act|
        action act do
          validate :user, :shellsafe
          do_user_action(act.to_sym)
        end
      end
      
      action "passwd" do
        validate :user, :shellsafe
        validate :passwd, :shellsafe
        require 'puppet'
        user = ::Puppet::Type.type(:user).create(:name => request[:user]).provider
        user.extend(ExtendPuppetUser)
        if user.ensure == :absent
          reply[:output] = "Fail: '" + request[:user] + "' does not exist"
        else
          user.password = request[:passwd]
          if user.getPW == request[:passwd]
            reply[:output] = "Success: '" + request[:user] + "' password changed"
          else
            reply[:output] = "Fail: '" + request[:user] + "' password NOT changed"
          end
        end
      end
      
      action "addgroup" do
        validate :user, :shellsafe
        validate :group, :shellsafe
        require 'puppet'
        user = ::Puppet::Type.type(:user).create(:name => request[:user]).provider
        user.extend(ExtendPuppetUser)
        group = ::Puppet::Type.type(:group).create(:name => request[:group]).provider
        if group.ensure == :absent
          reply[:output] = "Fail: '" + request[:group] + "' group does not exist"
        else
          if user.ensure == :absent
            reply[:output] = "Fail: '" + request[:user] + "' does not exist"
          else
            if user.groups.split(/,/).include?(request[:group])
              reply[:output] = "Fail: '" + request[:user] + "' is already in group '" + request[:group]
            else
              user.groups = user.groups + "," + request[:group]
              if user.groups.split(/,/).include?(request[:group])
                reply[:output] = "Success: '" + request[:user] + "' has been added to '" + request[:group]
              else
                reply[:output] = "Fail: '" + request[:user] + "' has NOT been added to '" + request[:group]
              end
            end
          end
        end
      end
      
      private
      def do_user_action(action)
        begin
          require 'puppet'
          user = ::Puppet::Type.type(:user).create(:name => request[:user]).provider
          user.extend(ExtendPuppetUser)
          
          reply[:output] = "blah"
          reply[:exitcode] = 0
          
          case action
            when :lock
              user.password = '!!' + user.getPW
              if user.isLocked
                reply[:output] = "Success: '" + request[:user] + "' is LOCKED"
              else
                reply[:output] = "Fail: '" + request[:user] + "' is NOT LOCKED"
              end
                
            when :status
              if user.ensure == :absent
                reply[:output] = "User '" + request[:user] + "' not found"
              else
                reply[:output] = "User '" + request[:user] + "' exists"
                reply[:output] = reply[:output] + " and is LOCKED" if user.isLocked
              end
              
            when :remove
              if user.ensure == :absent
                reply[:output] = "Success: '" + request[:user] + "' already didn't exist"
              else
                user.delete
                if user.ensure == :absent
                  reply[:output] = "Success: '" + request[:user] + "' removed"
                else
                  reply[:output] = "Fail: '" + request[:user] + "' was not removed"
                end
              end
              
            when :add
              if user.ensure == :present
                reply[:output] = "Success: '" + request[:user] + "' already exists"
              else
                user.create
                if user.ensure == :present
                  reply[:output] = "Success: '" + request[:user] + "' added"
                else
                  reply[:output] = "Fail: '" + request[:user] + "' was not added"
                end
              end
               
            else
              reply.fail "Unknown action #{action}"
          end
            
        rescue Exception => e
          reply.fail e.to_s
        end
      end
    end
  end
end