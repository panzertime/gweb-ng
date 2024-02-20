module server

include("db.jl")
include("auth.jl")
include("http.jl")


greet() = println("Prepared To Serve")

greet()
wait(serve(gweb))


end # module server
