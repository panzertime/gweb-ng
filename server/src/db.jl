using SQLite
using DataFrames
using JSONTables

con = DBInterface

db = SQLite.DB(get(ENV, "DATABASE", "server/src/sample.db.sql"))

podStmt = SQLite.Stmt(db, "SELECT p.id, p.title, p.cover_url, c.epcount"*
                " FROM podcast p"*
                " INNER JOIN (SELECT podcast_id, COUNT(podcast_id) as epcount"*
                "   FROM episode"*
                "   JOIN podcast"*
                "   ON podcast.id = episode.podcast_id"*
                "   GROUP BY podcast_id) c"*
                " on p.id = c.podcast_id"
)

episodesStmt = SQLite.Stmt(db, "SELECT e.id, e.title, e.published, e.description_html, j.pathname"*
                " FROM episode e"*
                " JOIN (SELECT  episode.id, download_folder || \"/\" || download_filename as pathname"*
                "        FROM episode"*
                "        JOIN podcast"*
                "        ON podcast.id=episode.podcast_id) j"*
                " ON j.id = e.id"*
                " WHERE e.podcast_id=?"*
                " ORDER BY e.published DESC"
)

mostRecentStmt = SQLite.Stmt(db, "SELECT e.id, e.title, e.published, e.description_html, j.pathname"*
                " FROM episode e"*
                " JOIN (SELECT  episode.id, download_folder || \"/\" || download_filename as pathname"*
                "        FROM episode"*
                "        JOIN podcast"*
                "        ON podcast.id=episode.podcast_id) j"*
                " ON j.id = e.id"*
                " ORDER BY e.published DESC"*
                " LIMIT 25"
)

function podListQuery()::AbstractString
    df = DataFrame(con.execute(podStmt))
    df_plusPages = select(df, :, :epcount => ByRow(epcount -> ceil(Integer, epcount / 25)) => :pagecount)
    return arraytable(df_plusPages)
end

function epsListQuery(pod_id::Integer)::AbstractString
    df = DataFrame(con.execute(episodesStmt, [pod_id]))
    return arraytable(df)
end

function mostRecentQuery()::AbstractString
    df = DataFrame(con.execute(mostRecentStmt))
    return arraytable(df)
end

function pagedEpsListQuery(pod_id::Integer, page::Integer)::AbstractString
    df = DataFrame(con.execute(episodesStmt, [pod_id]))
    # since we are using dataframes, which index from 1, we don't need to do crazy 1->0->1 base conversions like we did with Python gweb
    pageStart = 25 * page - 24
    # we still have to worry about running off the end of the table though
    tableEnd = size(df, 1)
    pageEnd = 25 * page
    page = df[pageStart:(pageEnd > tableEnd ? tableEnd : pageEnd), :]
    return arraytable(page)
end
