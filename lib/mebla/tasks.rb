Mebla.cofigure do |config|
  config.logger = Logger.new(STDOUT)
  config.setup_logger
end

namespace :mebla do
  desc "Creates the indeces and indexes the data for all indexed models"
  task :index => :environment do
    context = Mebla.context
    context.index_data
  end
  
  desc "Drops then creates the indeces and indexes the data for all indexed models"
  task :reindex => :environment do
    context = Mebla.context
    context.reindex_data
  end
  
  desc "Creates the index without indexing the data"
  task :create_index => :environment do
    context = Mebla.context
    context.create_index
  end
  
  desc "Rebuilds the index without indexing the data"
  task :rebuild_index => :environment do
    context = Mebla.context
    context.rebuild_index
  end
  
  desc "Drops the index"
  task :drop_index => :environment do
    context = Mebla.context
    context.drop_index
  end
  
  desc "Refreshes the index"
  task :refresh_index => :environment do
    context = Mebla.context
    context.refresh_index
  end
end