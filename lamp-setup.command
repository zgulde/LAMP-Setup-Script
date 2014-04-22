#!/usr/bin/env ruby

module Support
  extend self

  @@box_url = "http://goo.gl/ceHWg"

  def box_url
    @@box_url
  end

  def brew_install(package, *options)
    output = `brew list #{package}`
    return unless output.empty?

    system "brew install #{package} #{options.join ' '}"
  end

  def brew_cask_install(package, *options)
    output = `brew cask info #{package}`
    return unless output.include? 'Not installed'

    system "brew cask install #{package} #{options.join ' '}"
  end

  def git_clone(user, package, path)
    unless File.exist? File.expand_path(path)
      system "git clone https://github.com/#{user}/#{package} #{path}"
    end
  end

  def app_path(name)
    path = "/Applications/#{name}.app"
    ["~#{path}", path].each do |full_path|
      return full_path if File.directory?(full_path)
    end

    return nil
  end

  def app?(name)
    return !self.app_path(name).nil?
  end
end

module Steps
  extend self

  def heading(description)
    description = "-- #{description} "
    description = description.ljust(80, '-')
    puts
    puts "\e[32m#{description}\e[0m"
  end

  def block(description)
    words = description.split
    line = ''

    words.each { |word|
      if line.length + word.length > 77
        puts "   " + line
        line = ''
      end

      line += "#{word} "
    }

    puts "   " + line
    gets
  end

  def step(name)
    case name
      when "start"
        self.heading "Welcome!"
      when "xcode"
        self.heading "Setting up Xcode Commandline Tools"
      when "homebrew"
        self.heading "Setting up Homebrew"
      when "vagrant"
        self.heading "Setting Up Vagrant Box"
      when "git"
        self.heading "Checking Out Vagrant LAMP Repository"
      when "final"
        self.heading "Final Configuration Steps"
      else
        raise "Unknown step #{name}"
    end

    self.send(name)
  end

  def start
    description = "This script will go through and make sure you have all the tools you need to get started as a Codeup student. "
    description+= "At several points through this process, you may be asked for a password; this is normal. "
    description+= "Enter the password you use to log in to your computer or otherwise install software normally. "
    description+= "To get started press the 'Return' key on your keyboard."

    self.block description
  end

  def xcode
    `xcode-select --print-path 2>&1`

    if $?.success?
      self.block "Xcode commandline tool are already installed, moving on."
    else
      description = "We need to install some commandline tools for Xcode. When you press 'Return', a dialog will pop up "
      description+= "with several options. Click the 'Install' button and wait. Once the process completes, come back here "
      description+= "and we will proceed with the next step."

      self.block description

      system "xcode-select --install"

      while !$?.success?
        sleep 1

        `xcode-select --print-path 2>&1`
      end
    end
  end

  def homebrew
    `which brew`

    if $?.success?
      description = "Homebrew is already installed. We will check to make sure our other utilities--including Ansible, Vagrant, "
      description+= "and VirutalBox--are also set up."

      self.block description
    else
      description = "We will now install a tool called 'Homebrew'. This is a package manager we will use to install several "
      description+= "other utilities we will be using in the course, including Ansible, Vagrant, and VirtualBox. "
      description+= "You will probably be asked for your password a couple of times through this process; "
      description+= "when you type it in, your password will not be displayed on the screen. This is normal."

      self.block description

      system 'ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    end

    # Install brew cask
    system('brew tap | grep phinze/cask > /dev/null') || system('brew tap phinze/homebrew-cask')
    Support.brew_install 'brew-cask'

    # Install ansible
    Support.brew_install 'ansible'

    # Install Virtual Box
    Support.brew_cask_install "virtualbox" unless Support.app? "VirtualBox"

    # Install Vagrant
    Support.brew_cask_install "vagrant"
  end

  def vagrant
    boxes = `vagrant box list`

    if boxes.include? "codeup-raring"
      description = "Looks like you've already setup our vagrant box, we'll move on."

      self.block description
    else
      description = "Now we will download our vagrant box file. Vagrant is a utility for managing virtual machines, and "
      description+= "a box file contains a virtual machine definition and its code. Be patient! This file is a little over "
      description+= "400MB and will take a while to download."

      self.block description

      system "vagrant box add codeup-raring #{Support.box_url}"
    end
  end

  def git
    # Checkout vagrant-lamp repo

  end

  def final
    # Edit hosts file
    # Generate codeup_rsa key

  end
end

Steps.step "start"
Steps.step "xcode"
Steps.step "homebrew"
Steps.step "vagrant"
Steps.step "git"
Steps.step "final"