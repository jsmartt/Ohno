require 'chef/knife'

module Lnxchk
  class Ohno < Chef::Knife
    class MyUI < Chef::Knife::UI
      # Dummy class to proxy UI output to a data attribute
      attr_accessor :data

      def output(data)
        @data = data
      end
    end

    deps do
      require 'chef/knife/status'
      require 'chef/knife/search'
      require 'chef/search/query'
      require 'highline'
    end

    banner "knife ohno HOURS"

    option :id_only,
      short: '-i',
      long: '--id-only',
      description: 'Show only matching object IDs',
      boolean: true | false,
      default: false

    def run
      unless hours = name_args.first
        ui.error "You need to specify a number of hours behind the checkins are"
        exit 1
      end

      hours = hours.to_i

      knife_status = Chef::Knife::Status.new
      knife_status.ui = MyUI.new(STDOUT, STDERR, STDIN, config)
      knife_status.run
      hitlist = knife_status.ui.data

      cutoff_time = Time.now - hours * 3600
      hitlist.delete_if { |node| Time.at(node['ohai_time']) > cutoff_time rescue false }
      puts "#{hitlist.size} lost cheep in need of chefherding for more than #{hours} hours:\n\n"
      if config[:id_only]
        hitlist.each { |n| puts n['name'] }
      else
        puts knife_status.ui.presenter.format(hitlist)
      end
    end # close run
  end # close class
end # close module
