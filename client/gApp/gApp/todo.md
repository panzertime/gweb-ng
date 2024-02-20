#  <#Title#>

- Try out the more modern Navigation Stack - already done?
- Try shrinking the page selector down

- Make an HTML -> text cleaner - DONE


- New Server
 - Require authorization
 - Fix up model schema
    - Pods containing the ID. Containing episode, page counts
    - Episodes include the file URL - on client side turn this into a cacheable AVPlayerItem with the pre-downloaded file
    
    
- New Client
 - Use AVQueuePlayer ?
 - make an async loadFile() func on the Episode, should DL the file (necessary?) and when the PlayerItem is readyToPlay, add to the queue
 - Represent the queue as-is
