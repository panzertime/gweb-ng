#  <#Title#>

- New Server
 - Require authorization
 - Fix up model schema
    - Pods containing the ID. Containing episode, page counts
    - Episodes include the file URL - on client side turn this into a cacheable AVPlayerItem with the pre-downloaded file


pod list: 
            "SELECT id, title, cover_url"
            " FROM podcast"

episode count:
"SELECT podcast_id,"
            " COUNT(podcast_id)"
            " FROM episode"
            " JOIN podcast"
            " ON podcast.id = episode.podcast_id"
            " GROUP BY podcast_id"

list of episodes:
            "SELECT id, title, published, description_html"
            " FROM episode"
            " WHERE podcast_id=?"
            " ORDER BY published DESC",
    (need to add pagination logic)

get episode's URL:
            "SELECT download_folder, download_filename"
            " FROM episode"
            " JOIN podcast"
            " ON podcast.id=episode.podcast_id"
            " WHERE episode.id=?",

New Queries:
Pod ID, Title, Cover URL, and Ep Count:
    "SELECT p.id, p.title, p.cover_url, c.epcount"
    " FROM podcast p"
    " INNER JOIN (SELECT podcast_id, COUNT(podcast_id) as epcount FROM episode JOIN podcast ON podcast.id = episode.podcast_id GROUP BY podcast_id) c on p.id = c.podcast_id"

Episode Pathname:
SELECT download_folder || "/" || download_filename as path
             FROM episode
             JOIN podcast
             ON podcast.id=episode.podcast_id
             WHERE episode.id=?


Episode ID, title, publish date, HTML desc, and pathname for a podcast
            SELECT e.id, e.title, e.published, e.description_html, j.pathname
            FROM episode e
			JOIN (SELECT  episode.id, download_folder || "/" || download_filename as pathname
					FROM episode
					JOIN podcast
					ON podcast.id=episode.podcast_id) j
			ON j.id = e.id
			WHERE e.podcast_id=?
			ORDER BY e.published DESC			


			 