using Test, TestSetExtensions, SafeTestsets

include(joinpath(@__DIR__,"test_models.jl"))
module TestSetupTeardown

  using SearchLight
  using SearchLightOracle

  export prepareDbConnection, tearDown

  connection_file = "oracle_connection.yml"

  function prepareDbConnection()
      
    conn_info_oracle = SearchLight.Configuration.load(connection_file)
    conn = SearchLight.connect(conn_info_oracle)
    return conn
  end

  function tearDown(conn)
    if conn !== nothing
        ######## Dropping used tables
        SearchLight.Migration.drop_migrations_table()

        # insert tables you use in tests here
        tables = ["Book","BookWithIntern","Callback","Author","BookWithAuthor"]

        # obtain tables exists or not, if they does drop it
        wheres = join(map(x -> string("'", lowercase(SearchLight.Inflector.to_plural(x)), "'"), tables), " , ", " , ")
        queryString = string("select table_name from information_schema.tables where table_name in ($wheres)")
        result = SearchLight.query(queryString)
        for item in eachrow(result)
            try
                SearchLight.Migration.drop_table(lowercase(item[1]))
            catch ex
                @show "Table $item doesn't exist"
            end 
        end 
  
        SearchLight.disconnect(conn)
        rm(SearchLight.config.db_migrations_folder, force=true, recursive=true)
    end
  end

end

@safetestset "Connection test" begin
  using SearchLight
  using SearchLightOracle
  using Main.TestSetupTeardown

  connection_file = "oracle_connection.yml"
      
  conn_info_oracle = SearchLight.Configuration.load(connection_file)
  conn = SearchLight.connect(conn_info_oracle)
  SearchLight.connection()

  conn = prepareDbConnection()  
  @test conn !== nothing

  tearDown(conn)
  using Oracle
  Oracle.close(conn)

end