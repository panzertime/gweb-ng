//
//  ContentView.swift
//  gApp
//
//

import SwiftUI
import SwiftData
import AVFoundation

class gAppModel: ObservableObject {
    @Published var podList: [Pod]
    @Published var pageIndex: [Int: Int]
    @Published var selector: Selection
    @Published var episodesList: [Ep]
    
    func update() {
        let pods_url = URL(string: "https://pods.p-ti.me/pods")!
        let pods_task = URLSession.shared.dataTask(with: pods_url) { data, response, error in
            if let error = error {
                return // do nothing on error
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return // do nothing on error
            }
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
               let data = data {
                do {

                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else {
                        print("Failed initial deserialization of pods list")
                        print(String(bytes: data, encoding: String.Encoding.utf8))
                        return
                    }
                    var tempPods = [Pod]()
                    for row in Array(dictionary.keys).sorted(using: .localizedStandard){
                        let jPod = dictionary[row]!
                        print("adding row \(row)")
                        tempPods.append(Pod(coverUrl: String(describing: jPod["cover_url"]!), name: String(describing: jPod["title"]!), id: Int(row)!))
                    }
                    self.podList = tempPods
                } catch { print("Could not set pods = tempPods?")}
            }
        }
  
        let pages_url = URL(string: "https://pods.p-ti.me/episode_count")!
        let pages_task = URLSession.shared.dataTask(with: pages_url) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return // do nothing on error
            }
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
               let data = data {
                do {
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Int] else {
                        print("Could not parse episode counts")
                        print(String(bytes: data, encoding: String.Encoding.utf8))
                        return
                    }
                    for row in dictionary.keys {
                        // per reddit, the following simulates ceiling func on float division
                        let pages = ((dictionary[row]! + 24) / 25)
                        self.pageIndex[Int(row)!] = pages
                    }
                } catch {}
            }
        }
        pods_task.resume()
        pages_task.resume()
    }
    
    func refreshEpisodes() {
        let eps_url = URL(string: "https://pods.p-ti.me/get_episodes?podcast=\(selector.pod)&page=\(selector.page)")!
        let eps_task = URLSession.shared.dataTask(with: eps_url) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return // do nothing on error
            }
            if let mimeType = httpResponse.mimeType, mimeType == "application/json",
               let data = data {
                do {
                    let episodes = try JSONDecoder().decode([Ep].self, from: data)
                    self.episodesList = episodes
                } catch {}
            }
        }
        eps_task.resume()
    }
    
    func queueURL(completion: @escaping (URL) -> ()) {
        let url_url = URL(string: "https://pods.p-ti.me/queue_episode?id=\(selector.episode)")!
        print(url_url)
        let url_task = URLSession.shared.dataTask(with: url_url) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return // do nothing on error
            }
            if let mimeType = httpResponse.mimeType, mimeType.contains("text/html"),
               let data = data {
                let ep_url = String(data: data, encoding:.utf8)!
                print(ep_url)
                completion(URL(string: ep_url)!)
            }
        }
        url_task.resume()
    }
    
    init() {
        self.podList = [Pod(coverUrl: "", name: "", id: 0)]
        self.pageIndex = [0: 1, 1: 1]
        self.selector = Selection()
        self.episodesList = [Ep(description: "", id: 0, published: 0, title: "")]
        self.update()
        self.refreshEpisodes()
    }
}

struct Selection: Hashable {
    var pod: Int
    var page: Int
    var episode: Int
    var epIndexInPage: Int
    
    init() {
        self.pod = 1
        self.page = 0
        self.episode = 0
        self.epIndexInPage = 0
    }
}

struct Pod: Identifiable, Hashable {
    let coverUrl: String
    let name: String
    let id: Int
}

struct Ep: Identifiable, Hashable, Decodable {
    let description: String
    let id: Int
    let published: Int // maybe make this a date type
    let title: String
    
    func getDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/DD/yyy hh:MM"
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(published)))
    }
    
    func getRawDesc() -> String {
        let data = Data(description.utf8)
        if let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributed.string
        } else {
            return ""
        }
    }
    
    func getAttrDesc() -> AttributedString {
        let data = Data(description.utf8)
        if let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return AttributedString(attributed)
        }
        else {
            return AttributedString("")
        }
    }
    
    func getNaiveRawDesc() -> String {
        return description.replacingOccurrences(of: "</p>", with: "\n", options: .regularExpression, range: nil).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
}

func testURL(url: URL) {
    let url_task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return // do nothing on error
        }
        print(httpResponse.statusCode)
        print(httpResponse.allHeaderFields)
        print(httpResponse.mimeType)
    }
    url_task.resume()
}

var player: AVAudioPlayer!

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    //private let player = Player()
   // @StateObject private var player = AVAudioPlayer()
    
    @StateObject private var model = gAppModel()
    
    private func updatePlayer(url: URL) {
        print(player)
        //if (player != nil) {
         //   player.replaceCurrentItem(with: AVPlayerItem(url: url))
        //} else {
        //let uAsset = AVURLAsset(url: url)
        
     //   let aP = AVPlayerItem(asset: uAsset)
       // print(aP.status.rawValue)
      //  print(aP.error)
       // let metadata = try await uAsset.load(.metadata)
        if player != nil {
            player.stop()
        }
        let dl_task = URLSession.shared.dataTask(with: url) {
            data, response, error in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return // do nothing on error
                }
          //  let data = data {
            do {
                player = try AVAudioPlayer(data: data!)
                player.prepareToPlay()
                player.play(atTime: 0.0)
                //  }
                print(httpResponse.statusCode)
                print(httpResponse.allHeaderFields)
                print(httpResponse.mimeType)
            } catch {
                print("Some error: \(error)")
            }
        }
        dl_task.resume()
        /*
        do {
            print("URL being loaded is: \(url)")
            testURL(url: url)
            player = try AVAudioPlayer(contentsOf: url)
            print(player)
            player.prepareToPlay()
            
        } catch {
            print("some error in AVAudioPlayer init")
            print(error)
            return
        }*/


        //}
        
        print(player)
    }
    
    var body: some View {
        NavigationStack(root: {
            ScrollView(content: {
                VStack(spacing: 0.0) {
                    List {
                        HStack(spacing: 0.0) {
                            Picker("Pod", selection: $model.selector.pod) {
                                ForEach(model.podList) { pod in
                                    Text(pod.name)
                                }
                            }.onChange(of: model.selector.pod) {
                                model.selector.page = 1
                                model.refreshEpisodes()
                                model.selector.episode = 0
                            }
                            Picker("Page", selection: $model.selector.page) {
                                // need to get selectedPod, then add a row for each page in index count
                                ForEach(1..<(model.pageIndex[model.selector.pod]! + 1), id: \.self) { page_num in
                                    Text("\(page_num)")
                                }
                            }.onChange(of: model.selector.page) {
                                model.refreshEpisodes()
                                model.selector.episode = 0 //IndexInPage = 0
                            }.frame(maxWidth: 100)
                        }
                        
                        Picker("Episode", selection: $model.selector.episode, content: {
                            ForEach(model.episodesList) { ep in
                                Text(ep.title)
                            }
                        }).onChange(of: model.selector.episode) {
                            model.selector.epIndexInPage = model.episodesList.firstIndex(where: {$0.id == model.selector.episode}) ?? 0
                        }
                    }.frame(minHeight: 140, maxHeight: 150)//.padding(.bottom, 16)
                    
                    VStack(spacing:0.0){
                        List {
                            LabeledContent(model.podList[model.selector.pod - 1].name) {
                                AsyncImage(url: URL(string: model.podList[model.selector.pod - 1].coverUrl)) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(maxWidth: 300, maxHeight: 300, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            }.font(.headline)
                        }.frame(minHeight: 310, maxHeight: 350)//.padding(.bottom, 16)
                        
                        List {
                            VStack(spacing:0.0) {
                                Text(model.episodesList[model.selector.epIndexInPage].title)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Text(model.episodesList[model.selector.epIndexInPage].getDate()) //     $("#ep-date").html(new Date(episode.published * 1000).toLocaleDateString());
                                    .font(.subheadline)
                            }
                            Text(model.episodesList[model.selector.epIndexInPage].getNaiveRawDesc())
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }.frame(minHeight: 300, maxHeight: 450)//.padding(.top, -48)
                    }
                    
                    VStack(spacing: 0.0) {
                        Button {
                            model.queueURL(completion: {
                                updatePlayer(url: $0)
                            })
                        } label: {
                            Label("Queue Episode", systemImage: "speaker.wave.2.bubble.left.rtl")
                        }
                        HStack(spacing: 0.0) {
                            Button {
                                if player.isPlaying {
                                    return
                                }
                                player.play()
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            Button {
                                player.pause()
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                            }
                        }
                    }
                }

            })
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button(action: {model.update()} ) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }.navigationTitle("gApp").navigationBarTitleDisplayMode(.inline)
        }).onAppear{
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
           }
           catch {
               print("Setting category to AVAudioSessionCategoryPlayback failed.")
           }
        } //refreshPods() }
    }
}

#Preview {
    ContentView()
       // .modelContainer(for: gAppModel.self, inMemory: true)
}
