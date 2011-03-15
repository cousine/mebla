namespace :mebla do
  desc "Creates the indeces and indexes the data for all indexed models"
  task :index => :environment do
    context = Mebla::Context.instance
    context.index_data
  end
  
  desc "Drops then creates the indeces and indexes the data for all indexed models"
  task :index => :environment do
    context = Mebla::Context.instance
    context.reindex_data
  end
end