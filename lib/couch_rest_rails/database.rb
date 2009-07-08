module CouchRestRails
  module Database

    extend self

    def create(database)
      return  "Database '#{database}' doesn't exists" unless
        (database == "*" || File.exist?(File.join(RAILS_ROOT,
                                                  CouchRestRails.setup_path,
                                                  database)))

      # get list of available_databases in couch...
      existing_databases = COUCHDB_SERVER.databases
      # get all the model files
      Dir[File.join(RAILS_ROOT, CouchRestRails.setup_path,database)].each do |db|
        # check for a directory...
        if File::directory?( db )
          database_name =COUCHDB_CONFIG[:db_prefix] +  File.basename(db) +
            COUCHDB_CONFIG[:db_suffix]
          if existing_databases.include?(database_name)
            puts "The CouchDB database '#{database_name}' already exists"
          else
            # create the database
            COUCHDB_SERVER.create_db(database_name)
            puts "Created the CouchDB database '#{database_name}'"
            # create views on database
            puts CouchRestRails::Views.push(File.basename(db),"*")
            # create lucene-searches
            puts CouchRestRails::Lucene.push(File.basename(db),"*")
          end
        end
      end
      "create complete"
    end

    def delete(database)
      return  "Database '#{database}' doesn't exists" unless
        (database == "*" || File.exist?(File.join(RAILS_ROOT,
                                                  CouchRestRails.setup_path,
                                                  database)))
      # get list of available_databases in couch...
      existing_databases = COUCHDB_SERVER.databases
      # get all the model files
      Dir[File.join(RAILS_ROOT, CouchRestRails.setup_path,database)].each do |db|
        # check for a directory...
        if File::directory?( db )
          database_name =COUCHDB_CONFIG[:db_prefix] +  File.basename(db) +
            COUCHDB_CONFIG[:db_suffix]
          if existing_databases.include?(database_name)
            CouchRest.delete "#{COUCHDB_CONFIG[:host_path]}/#{database_name}"
            puts "Dropped CouchDB database '#{database_name}'"
          else
            puts "The CouchDB database '#{database_name}' does not exist"
          end
        end
      end
      "delete complete"
    end
  end
end
