#\ -s puma
require './app'
use Rack::Cors do
  allow do
    origins '*'
    resource '/public/*', :headers => :any, :methods => :get
  end
end
end
$stdout.sync = true
run MyApp.run!
