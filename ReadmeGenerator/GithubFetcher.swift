//
//  GithubFetcher.swift
//  ReadmeGenerator
//
//  Created by Petr Korolev on 20.02.2020.
//  Copyright © 2020 Serhii Londar. All rights reserved.
//

import Foundation
import GithubAPI

class GithubFetcher: NSObject, URLSessionTaskDelegate {

    // Can't init is singleton


    // MARK: Shared Instance

    static let shared = GithubFetcher()

    var session: URLSession!
    var token: String

    private override init() {
        token = ""
        super.init()
        token = self.retrieveToken().trimmingCharacters(in:
        NSCharacterSet.whitespacesAndNewlines
        )
        self.initializeSession()

    }

    func initializeSession() {
        // Create a new session with APIClient as the delegate
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "token " + token]
        print(config.httpAdditionalHeaders)
        session = URLSession(configuration: config,
                delegate: self,
                delegateQueue: nil)
    }


    // Implement URLSessionTaskDelegate's HTTP Redirection method
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // Create a mutable copy of the new request, add the header, call completionHandler
        let newRequest = request
        completionHandler(newRequest)
    }

    func retrieveToken() -> String {
        do {
            let thisFilePath: String = #file
            let url = URL(fileURLWithPath: thisFilePath).deletingLastPathComponent().appendingPathComponent(FilePaths.github_token.rawValue)

            let data = try Data(contentsOf: url)
            let GITHUB_TOKEN = String(decoding: data, as: UTF8.self)
            return GITHUB_TOKEN
        } catch {
            print(error)
        }
        return ""
    }

    func getStarsForUrl(gh_link: String) -> Int? {
        var stars: Int? = nil
        do {
            do {
                let gh_url = NSURL(string: gh_link)
                let comp = gh_url?.pathComponents
                if let comp = comp {
                    guard comp.count > 2 else {
                        return nil
                    }
                    let owner = comp[1]
                    let repo = comp[2]
                    let baseUrl = "https://api.github.com"
                    let path = "/repos/\(owner)/\(repo)"
                    let url = URL(string: baseUrl + path)
                    if let url = url {
                        var dataTask: URLSessionDataTask?
                        dataTask?.cancel()
                        let semaphore = DispatchSemaphore(value: 0)
                        dataTask =
                                session.dataTask(with: url) { data, response, error in
                                    do {
                                        if let error = error {
                                            print("DataTask error: " +
                                            error.localizedDescription + "\n")
                                        } else if
                                                let data = data,
                                                let response = response as? HTTPURLResponse,
                                                response.statusCode == 200 {
                                            let model = try JSONDecoder().decode(RepositoryResponse.self, from: data)

                                            // 6
                                            if let starz = model.stargazersCount {
                                                stars = starz
                                            }
                                        }
                                        semaphore.signal()
                                    } catch {
                                        semaphore.signal()
                                    }
                                }
                        dataTask?.resume()
                        _ = semaphore.wait(wallTimeout: .distantFuture)

                    }
                }
            } catch {
                print(error)
            }
        }
        return stars

    }
}
