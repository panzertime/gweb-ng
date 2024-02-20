using DataFrames
using CSV
using Dates
using UUIDs

# we probably want something where clientname:secret is in a CSV,
# then we read that in as a DF at startup.
# Each request has a session cookie - stored in another DF here, probably with
# an expiry timestamp, whatever.
# if a request comes in w/o a valid cookie, make the client go to /auth/clientname/secret,
# if it's valid return a new cookie and store in the local DF.
# How do we communicate to the client? Probably just 403 - client should do auth step and retry if 403 happens
# Web client can just have WebClient:NoSecret built right into the page javascript, we can remove it when app client is ready

clientDB = CSV.read(get(ENV, "CLIENTDB", "server/src/sample.clients.csv"), DataFrame; header=["clientname","clientsecret"], comment="#", delim=":", types=String)
println(clientDB)

sessions = DataFrame([String[],String[],DateTime[]], ["clientname", "sessionid", "expiry"])

function isActiveSession(sessionid::String)::Bool
    # check if sessionid is in the sessions DF, and if expiry is after now
    stamp = sessions[sessions.sessionid .== sessionid, :expiry]
    if isempty(stamp)
        return false
    elseif now() > first(stamp)
        return false
    end
    return true
end

function authenticateUser(clientname::AbstractString, secret::AbstractString)::Bool
    dbsecret = clientDB[clientDB.clientname .== clientname, :clientsecret]
    if isempty(dbsecret)
        return false
    elseif first(dbsecret) != secret
        return false
    end
    return true
end

function addSession(clientname::AbstractString)::String
    # we need to delete any existing session
    # then add a new session
    # and send the session id back to the caller.
    deleteat!(sessions, findall(sessions.clientname .== clientname))
    newId = string(uuid1())
    newSession = DataFrame(clientname = clientname, sessionid = newId, expiry = (now() + Dates.Hour(48)))
    append!(sessions, newSession)
    return newId
end
