using Mux
using HttpCommon

key = "SAMPLE"

function getPodList()::AbstractString
    return podListQuery()
end

function getEpList(pod_id::AbstractString)::AbstractString
    return getEpList(tryparse(Integer, pod_id))
end

function getEpList(pod_id::AbstractString, page::AbstractString)::AbstractString
    return getEpListPage(tryparse(Integer, pod_id), tryparse(Integer, page))
end

function getEpListPage(pod_id::Integer, page::Integer)::AbstractString
    return pagedEpsListQuery(pod_id, page)
end

function getEpList(pod_id::Integer)::AbstractString
    return epsListQuery(pod_id)
end

function authenticate(clientname::AbstractString, clientsecret::AbstractString)::AbstractString
    if authenticateUser(clientname, clientsecret)
        return addSession(clientname)
    end
    # this next line is not working
    mux(status(403), respond("403 Unauthorized"))
    # check for auth, send back 403 if NO, make session and return cookie if YES
end

function withJsonHeader(res)
    headers = HttpCommon.headers()
    headers["Content-Type"] = "application/json"
    return Dict(
        :headers => headers,
        :body => res
    )
end

function authorizationCheck(token_value)
    if token_value != key
        status(403)
    end
end

@app auth = (
    Mux.defaults,
    route("/", req -> authorizationCheck(req[:headers][:token_value]))
)

@app gweb = (
    Mux.defaults,
    page("/pods", res -> withJsonHeader(getPodList())),
    page("/episodes/:pod_id", req -> withJsonHeader(getEpList(req[:params][:pod_id]))),
    page("/episodes/:pod_id/:page", req -> withJsonHeader(getEpList(req[:params][:pod_id], req[:params][:page]))),
    page("/auth/:clientname/:clientsecret", req -> authenticate(req[:params][:clientname], req[:params][:clientsecret])),
    Mux.notfound()
)

