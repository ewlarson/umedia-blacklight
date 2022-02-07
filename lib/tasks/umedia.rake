# frozen_string_literal: true

require 'faraday'

desc 'Run test suite'
task :ci do
  shared_solr_opts = { managed: true, verbose: true, persist: false, download_dir: 'tmp' }
  shared_solr_opts[:version] = ENV['SOLR_VERSION'] if ENV['SOLR_VERSION']

  success = true
  SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: 'tmp/blacklight-core')) do |solr|
    solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
      system 'RAILS_ENV=test bundle exec rake umedia:index:seed'
      success = system 'RUBYOPT=W0 RAILS_ENV=test TESTOPTS="-v" bundle exec rails test:system test'
    end
  end

  exit!(1) unless success
end

namespace :umedia do
  desc 'Run Solr and UMedia for interactive development'
  task :server, [:rails_server_args] do
    require 'solr_wrapper'

    shared_solr_opts = { managed: true, verbose: true, persist: false, download_dir: 'tmp' }
    shared_solr_opts[:version] = ENV['SOLR_VERSION'] if ENV['SOLR_VERSION']

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8983, instance_dir: 'tmp/blacklight-core')) do |solr|
      solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Solr running at http://localhost:8983/solr/blacklight-core/, ^C to exit"
        puts ' '
        begin
          Rake::Task['umedia:index:seed'].invoke
          system "bundle exec rails s -b 0.0.0.0"
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  desc "Start solr server for testing."
  task :test do
    if Rails.env.test?
      shared_solr_opts = { managed: true, verbose: true, persist: false, download_dir: 'tmp' }
      shared_solr_opts[:version] = ENV['SOLR_VERSION'] if ENV['SOLR_VERSION']

      SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: 'tmp/blacklight-core')) do |solr|
        solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
          puts "Solr running at http://localhost:8985/solr/#/blacklight-core/, ^C to exit"
          begin
            Rake::Task['umedia:index:seed'].invoke
            sleep
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    else
      system('rake umedia:test RAILS_ENV=test')
    end
  end

  desc "Start solr server for development."
  task :development do
    shared_solr_opts = { managed: true, verbose: true, persist: false, download_dir: 'tmp' }
    shared_solr_opts[:version] = ENV['SOLR_VERSION'] if ENV['SOLR_VERSION']

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8983, instance_dir: 'tmp/blacklight-core')) do |solr|
      solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Solr running at http://localhost:8983/solr/#/blacklight-core/, ^C to exit"
        begin
          Rake::Task['umedia:index:seed'].invoke
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  namespace :index do
    desc 'Put all sample data into solr'
    task :seed => :environment do
      docs = Dir['test/fixtures/files/**/*.json'].map { |f| JSON.parse File.read(f) }.flatten
      Blacklight.default_index.connection.add docs
      Blacklight.default_index.connection.commit
    end

    desc 'Put umedia sample data into solr'
    task :umedia => :environment do
      docs = Dir['test/fixtures/files/umedia_documents/*.json'].map { |f| JSON.parse File.read(f) }.flatten
      Blacklight.default_index.connection.add docs
      Blacklight.default_index.connection.commit
    end

    desc 'Delete all sample data from solr'
    task :delete_all => :environment do
      Blacklight.default_index.connection.delete_by_query '*:*'
      Blacklight.default_index.connection.commit
    end

    desc 'Harvest'
    task :harvest => :environment do
      # mpls          => MDL collection
      # p16022coll262 => UMedia video collection
      # p16022coll208 => UMedia WWII poster collection
      # p16022coll171 => UMedia audio collection
      # p16022coll282 => UMedia compound objects (ex. p16022coll282:6571)

      example_sets = [
        "p16022coll262", "p16022coll208", "p16022coll171", "p16022coll282"
      ]

      example_sets.each do |set|
        CDMDEXER::ETLWorker.new.perform(
          'solr_config' => {:url=>ENV['SOLR_URL']},
          'oai_endpoint' => ENV['OAI_ENDPOINT'],
          'cdm_endpoint' => ENV['CDM_ENDPOINT'],
          'set_spec' => set,
          'batch_size' => 10,
          'max_compounds' => 10
        )
      end
    end

    desc 'Backup'
    task :backup => :environment do
      solr = ENV['SOLR_URL']
      replication = 'replication?command=backup'

      res = Faraday.get "#{solr}/#{replication}"
      puts res.body

      sleep(10)

      snapshots = Dir.glob("#{Rails.root.join('tmp/blacklight-core/server/solr/blacklight-core/data/snapshot.*')}")

      FileUtils.cp_r(snapshots, "#{Rails.root.join('solr/snapshots')}")
    end

    task :restore => :environment do
      solr = ENV['SOLR_URL']
      replication = 'replication?command=restore'

      snapshot = Dir.glob("#{Rails.root.join('solr/snapshots/snapshot.*')}").last

      FileUtils.cp_r(snapshot, "#{Rails.root.join('tmp/blacklight-core/server/solr/blacklight-core/data')}")

      res = Faraday.get "#{solr}/#{replication}"
      puts res.body
    end
  end
end
