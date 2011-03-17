namespace :mebla do
  desc "Creates the indeces and indexes the data for all indexed models"
  task :index => :environment do
    setup
    @context.index_data
  end
  
  desc "Drops then creates the indeces and indexes the data for all indexed models"
  task :reindex => :environment do
    setup
    @context.reindex_data
  end
  
  desc "Creates the index without indexing the data"
  task :create_index => :environment do
    setup
    @context.create_index
  end
  
  desc "Rebuilds the index without indexing the data"
  task :rebuild_index => :environment do
    setup
    @context.rebuild_index
  end
  
  desc "Drops the index"
  task :drop_index => :environment do
    setup
    @context.drop_index
  end
  
  desc "Refreshes the index"
  task :refresh_index => :environment do
    setup
    @context.refresh_index
  end
end

def setup
  Rails.application.eager_load!
  Mebla.configure do |config|
    config.logger = ActiveSupport::BufferedLogger.new(STDOUT)
    config.logger.level = ActiveSupport::BufferedLogger::Severity::UNKNOWN
    config.setup_logger
  end
  @context = Mebla.context
end