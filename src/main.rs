use std::env;
use warp::Filter;

fn get_port() -> u16 {
  let the_var = env::var("PORT");
  match the_var {
    Ok(str) => str.parse::<u16>().unwrap(),
    Err(_)=> 3000,
  }
}

// example taken from https://github.com/seanmonstar/warp#example
#[tokio::main]
async fn main() {

  let index = warp::path::end().map(|| "Ok");
  
  let hello = warp::path!("hello" / String)
    .map(|name| format!("Hello, {}!", name));

  let port = get_port();
  println!("selected port: {:?}", port);

  // @TODO find out how to use different HTTP methods for different handlers
  let routes = warp::get()
    .and(index)
    .or(hello);

  warp::serve(routes)
    .run(([0, 0, 0, 0], port))
    .await;

}
