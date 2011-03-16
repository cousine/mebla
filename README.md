Mebla
====

Mebla is an [elasticsearch](http://www.elasticsearch.org) wrapper for [Mongoid](http://mongoid.org) based on 
[Slingshot](https://github.com/karmi/slingshot).

Name
---------

Mebla is derived from the word "Nebla", which means slingshot in arabic.

Also since its a wrapper for mongoid ODM, the letter "N" is replaced with "M".

Installation
---------------

### Install elasticsearch

Mebla requires a running [elasticsearch](http://www.elasticsearch.org) installation.

To install elasticsearch follow the uptodate instructions [here](http://www.elasticsearch.org/guide/reference/setup/) or
simply copy and paste in your terminal window:

    $ curl -k -L -o elasticsearch-0.15.0.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.15.0.tar.gz
    $ tar -zxvf elasticsearch-0.15.0.tar.gz
    $ ./elasticsearch-0.15.0/bin/elasticsearch -f

### Install Mebla

Once elasticsearch is installed, add Mebla to your gem file:

    gem "mebla"
    
then run bundle in your application root to update your gems' bundle:

    $ bundle install
    
next generate the configuration file:

    $ rails generate mebla:install
    
finally index your data:

    $ rake mebla:index_data
    
Usage
---------

### Defining indexed fields

To enable searching models, you first have to define which fields mebla should index:

    class Post
      include Mongoid::Document
      include Mongoid::Mebla
      field :title
      field :author
      field :body
      field :publish_date, :type => Date
      field :tags, :type => Array
      
      embeds_many :comments
      search_in :author, :body, :publish_date, :tags, :title => { :boost => 2.0, :analyzer => 'snowball' }
    end
    
In the example above, mebla will index the author field, body field, publish_date field and finally indexes
the title field with some custom [mappings](http://www.elasticsearch.org/guide/reference/mapping).

#### Embedded documents

You can also index embedded documents as follows:

    class Comment
      include Mongoid::Document
      include Mongoid::Mebla
      field :comment
      field :author
      
      embedded_in :blog_post
      search_in :comment, :author, :embedded_in => :blog_post
    end
    
This will index all comments and make it available for searching directly through the Comment model.

### Searching the index

Mebla supports two types of search, index search and model search; in index search Mebla searches
the index and returns all matching documents regardless of their types, in model search however
Mebla searches the index and returns matching documents of the model(s) type(s).
documents

Mebla performs search using [Slingshot's searching DSL](http://karmi.github.com/slingshot/), I encourage
you to check the tutorial to have a broader view of slingshot's capabilities.

#### Index searching

Using the same models we defined above, we can search for all posts and comments with the author "cousine":

    Mebla.search do
      query do
        string "author: cousine"
      end
    end

This will return all documents with an author set to "cousine" regardless of their type, if we however want to
search only Posts and Comments, we would explicitly tell Mebla:

    Mebla.search [:post, :comment] do 
      query { string "author: cousine" }
    end
    
As shown above, you can also use the shorthand notation of ruby blocks.

#### Model searching

Instead of searching all models like index searching, we can search one model only:

    Post.search do
      query { string "title: Testing Search" }
      
      filter :term, :author => "cousine"
      filter :terms, :tags => ["ruby", "rails"]
      
      sort { publish_date "desc" }
      
      facet 'tags' do
        terms :tags, :global => true
      end
      
      facet 'authors' do
        terms :author
      end
    end
    
In the above example we are taking full advantage of slingshot's searching capabilities, 
we are getting all posts with the title "Testing Search", filtering the results with author 
"cousine", tagged "ruby" or "rails", and sorting the results with their publish_date fields.

One more feature we are using is "Faceted Search", from Slingshot's homepage:

> _Faceted Search_
>
> _ElasticSearch makes it trivial to retrieve complex aggregated data from the index/database, so called 
[facets](http://www.lucidimagination.com/Community/Hear-from-the-Experts/Articles/Faceted-Search-Solr)._

In the example above we are retrieving two facets, "tags" and "authors"; "tags" are global
which means that we want to get the counts of posts for each tag over the whole index, "authors"
however will only get the count of posts matching the search query for each author.

You can find more about searching [here](http://karmi.github.com/slingshot/)

#### Retrieving results

To retrieve the results of the model search we performed above we would simply:

    hits = Post.search do
      query { string "title: Testing Search" }
      
      filter :term, :author => "cousine"
      filter :terms, :tags => ["ruby", "rails"]
      
      sort { publish_date "desc" }
      
      facet 'tags' do
        terms :tags, :global => true
      end
      
      facet 'authors' do
        terms :author
      end
    end
    
    hits.each do |hit|
      puts hit.title
    end
    
To retrieve the facets:

    # Get the count of posts for each tag accross the index
    hits.facets['tags']['terms'].each do |facet|
      puts "#{facet['term']} : #{facet['count']}"
    end
    
    # Get the count of posts matching the query for each author
    hits.facets['authors']['terms'].each do |facet|
      puts "#{facet['term']} : #{facet['count']}"
    end
    
### Indexing data

#### Synchronizing data

By default Mebla synchronizes all changes done to your models with your index, if however
you would like to bypass this behavior:

    Post.without_indexing do
      Post.create :title => "This won't be indexed"
    end
    
#### Indexing existing data

You can index existing data by using the "index" rake task:

    $ rake mebla:index
    
This will create the index and index all the data in the database

#### Reindexing

Just like indexing, you can reindex your data using the "reindex" rake task:

    $ rake mebla:reindex
    
This will rebuild the index and index all your data again, note that unlike other full-text
search engines, you don't need to reindex your data frequently (if ever) however you 
might want to refresh the index so changes are reflected on the index.

#### Refreshing the index

Refreshing the index makes changes done to the index available for searching or modification.

Mebla automatically refreshes the index whenever a change is done, but just incase you
need to refresh the index:

    $ rake mebla:refresh
    
### Rake tasks

Mebla provides a number of rake tasks to perform various tasks on the index, you can
list all tasks using this command:

    $ rake -T mebla

Contributing to Mebla
----------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
-------------

Copyright (c) 2011 Omar Mekky. See LICENSE.txt for
further details.

