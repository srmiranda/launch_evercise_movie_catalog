require 'sinatra'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  db_connection do |conn|
    actors = conn.exec('SELECT name FROM actors ORDER BY name')
    erb :'actors/index', locals: { actors: actors }
  end
end

get "/actors/:actor_name" do
  actor_name = params[:actor_name]
    db_connection do |conn|
    work_details = conn.exec_params('
      SELECT movies.title, movies.year, cast_members.character
      FROM actors
      JOIN cast_members
      ON actors.id = cast_members.actor_id
      JOIN movies
      ON movies.id = cast_members.movie_id
      WHERE actors.name = ($1)', [params[:actor_name]])
    erb :'actors/show', locals: { actor_name: params[:actor_name], work_details: work_details }
  end
end

get '/movies' do
  db_connection do |conn|
    movies = conn.exec('
    SELECT movies.title, movies.year, movies.rating, genres.name "genre", studios.name "studio"
    FROM movies
    JOIN studios
    ON movies.studio_id = studios.id
    JOIN genres
    ON movies.genre_id = genres.id
    ORDER BY movies.title')
    erb :'movies/index', locals: { movies: movies }
  end
end

get '/movies/:movie_name' do
  movie_name = params[:movie_name]
  db_connection do |conn|
    movie_details = conn.exec('
    SELECT actors.name "actor", cast_members.character, genres.name "genre", studios.name "studio"
    FROM movies
    JOIN cast_members
    ON cast_members.movie_id = movies.id
    JOIN actors
    ON actors.id = cast_members.actor_id
    JOIN studios
    ON movies.studio_id = studios.id
    JOIN genres
    ON movies.genre_id = genres.id
    WHERE movies.title = ($1)', [params[:movie_name]])

    genre_studio = conn.exec('
    SELECT genres.name "genre", studios.name "studio"
    FROM movies
    JOIN studios
    ON movies.studio_id = studios.id
    JOIN genres
    ON movies.genre_id = genres.id
    WHERE movies.title = ($1)', [params[:movie_name]])

    erb :'movies/show', locals: { movie_name: params[:movie_name],
       movie_details: movie_details, genre_studio: genre_studio }
  end
end



set :views, File.join(File.dirname(__FILE__), "views")
set :public_folder, File.join(File.dirname(__FILE__), "public")
