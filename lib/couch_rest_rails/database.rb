module CouchRestRails
  module Database
    include FileUtils

    extend self
    
    def create(database_name = '*')
      
      # If wildcard passed, use model definitions for database names
      if database_name == '*'
        databases = CouchRestRails::Database.list
      else
        databases = [database_name]
      end
      
      response = ['']
      
      databases.each do |db|
        
        # Setup up views directory
        database_views_path = File.join(RAILS_ROOT, CouchRestRails.views_path, db, 'views')
        unless File.exist?(database_views_path)
          FileUtils.mkdir_p(database_views_path)
          response << "Created #{File.join(CouchRestRails.views_path, db, 'views')} views directory"
        end
        
        # Setup the Lucene directory if enabled
        if CouchRestRails.use_lucene
          database_lucene_path = File.join(RAILS_ROOT, CouchRestRails.lucene_path, db, 'lucene')
          unless File.exist?(database_views_path)
            FileUtils.mkdir_p(database_views_path)
            response << "Created #{File.join(CouchRestRails.lucene_path, db, 'lucene')} Lucene directory"
          end
        end
        
        # Create the database
        full_db_name = [COUCHDB_CONFIG[:db_prefix], File.basename(db), COUCHDB_CONFIG[:db_suffix]].join
        if COUCHDB_SERVER.databases.include?(full_db_name)
          response << "Database #{db} (#{full_db_name}) already exists"
        else
          COUCHDB_SERVER.create_db(full_db_name)
          response << "Created database #{db} (#{full_db_name})"
        end
        
        # Push up the views
        response << CouchRestRails::Views.push(File.basename(db), "*")
        
        # Push up Lucene doc if Lucene enabled
        response << CouchRestRails::Lucene.push(File.basename(db), "*") if CouchRestRails.use_lucene
        
      end
      response << ['']
      response.join("\n")
    end

    def delete(database_name = '*')
      
      # If wildcard passed, use model definitions for database names
      if database_name == '*'
        databases = CouchRestRails::Database.list
      else
        databases = [database_name]
      end
      
      response = ['']
      
      databases.each do |db|
        full_db_name = [COUCHDB_CONFIG[:db_prefix], File.basename(db), COUCHDB_CONFIG[:db_suffix]].join
        if !COUCHDB_SERVER.databases.include?(full_db_name)
          response << "Database #{db} (#{full_db_name}) does not exist"
        else
          CouchRest.delete "#{COUCHDB_CONFIG[:host_path]}/#{full_db_name}"
          response << "Deleted database #{db} (#{full_db_name})"
        end
      end
      response << ''
      response.join("\n")
    end

    def list
      databases = []
      Object.subclasses_of(CouchRestRails::Document).collect do |doc|
        raise "#{doc.name} does not have a database defined" unless doc.database
        databases << doc.unadorned_database_name
      end
      databases.sort.uniq
    end

  end
end
