//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class MovieController {
    // MARK: - LAMBDA
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    
    // MARK: - Properties
    var searchedMovies: [MovieRepresentation] = []
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error searching for movie: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    // MARK: - FIREBASE
    
    private let firebaseURL = URL(string: "https://mymovies-e674e.firebaseio.com/")!
    
    func searchForMovie(uuid: UUID, context: NSManagedObjectContext) -> Movie? {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", uuid as NSUUID)
        
        var searchResult: Movie? = nil
        context.performAndWait {
            do {
                searchResult = try context.fetch(fetchRequest).first
            } catch {
                NSLog("Error finding movie: \(error)")
            }
        }
        return searchResult
    }
    
    func fetchMovies(completion: @escaping ((Error?) -> Void) = { _ in }) {
        let requestURL = firebaseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                print("Error retrieving movies from server: \(error)")
                completion(error)
                return
            }
            guard let data = data else {
                print("Error accessing data retrieved from server: \(error!)")
                completion(nil)
                return
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                let movieRepresentations = try jsonDecoder.decode([String: MovieRepresentation].self, from: data).map({$0.value})
                
                try self.updateMovies(movieRepresentations: movieRepresentations, context: CoreDataStack.shared.container.newBackgroundContext())
                completion(nil)
            } catch {
                print("Error decoding data retrieved from server: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    func put(movie: Movie, completion: @escaping((Error?) -> Void) = { _ in }) {
        
        guard let identifier = movie.identifier, let movieRep = movie.movieRep else {
            completion(NSError())
            return
        }
        
        let requestURL = firebaseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        let jsonEncoder = JSONEncoder()
        
        do {
            request.httpBody = try jsonEncoder.encode(movieRep)
        } catch {
            print("Error PUTting Movie to Firebase: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
        
    }
    
    private func updateMovies(movieRepresentations: [MovieRepresentation], context: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        
        var error: Error?
        context.performAndWait {
            for movieRep in movieRepresentations {
                if let movie = self.searchForMovie(uuid: movieRep.identifier ?? UUID(), context: CoreDataStack.shared.mainContext) {
                    self.updateCoreData(movie: movie, movieRep: movieRep)
                } else {
                    let _ = Movie(movieRep: movieRep, context: context)
                }
            }
            
            do {
                try context.save()
            } catch let caughtError {
                error = caughtError
            }
        }
        
        if let error = error { throw error }
    }
    
    func deleteMovieFromServer(movie: Movie, completion: @escaping ((Error?) -> Void) = { _ in }) {
        guard let identifier = movie.identifier else {
            completion(nil)
            return
        }
        
        let requestURL = firebaseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                print("Error deleting movie from server: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    // MARK: - CRUD
    func saveMovie(movieRep: MovieRepresentation) {
        guard let movie = Movie(movieRep: movieRep) else { return }
        
        do {
            try CoreDataStack.shared.save()
            put(movie: movie)
        } catch {
            NSLog("Error toggling hasWatched: \(error)")
        }
    }
    
    private func updateCoreData(movie: Movie, movieRep: MovieRepresentation) {
        guard let hasWatched = movieRep.hasWatched else { return }
        
        movie.title = movieRep.title
        movie.hasWatched = hasWatched
        movie.identifier = movieRep.identifier
    }
    
    func deleteFromCoreData(movie: Movie) {
        CoreDataStack.shared.mainContext.delete(movie)
        deleteMovieFromServer(movie: movie)
        
        do {
            try CoreDataStack.shared.save()
        } catch {
            print("Error deleting movie from database: \(error)")
        }
    }
    
    func toggleHasWatched(movie: Movie) {
        movie.hasWatched.toggle()
        
        do {
            try CoreDataStack.shared.save()
            put(movie: movie)
        } catch {
            NSLog("Error toggling hasWatched: \(error)")
        }
    }
}
