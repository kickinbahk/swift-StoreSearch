//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Josiah Mory on 10/31/16.
//  Copyright © 2016 kickinbahk Productions. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
  
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var segmentedControl: UISegmentedControl!

  var searchResults: [SearchResult] = []
  var hasSearched = false
  var isLoading = false
  var dataTask: URLSessionDataTask?
  var landscapeViewController: LandscapeViewController?
  
  struct StandardMarginAndHeights {
    static let topMarginForSearchAndCategoryBar: CGFloat = 108
    static let noMargin: CGFloat = 0
    static let rowHeight: CGFloat = 80
  }
  
  struct TableViewCellIdentifiers {
    static let searchResultCell = "SearchResultCell"
    static let nothingFoundCell = "NothingFoundCell"
    static let loadingCell = "LoadingCell"
  }


  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.contentInset = UIEdgeInsets(top: StandardMarginAndHeights.topMarginForSearchAndCategoryBar,
                                          left: StandardMarginAndHeights.noMargin,
                                          bottom: StandardMarginAndHeights.noMargin,
                                          right: StandardMarginAndHeights.noMargin)
    var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
    tableView.rowHeight = StandardMarginAndHeights.rowHeight
    
    cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
    cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
    
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)

    searchBar.becomeFirstResponder()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowDetail" {
      let detailViewController = segue.destination as! DetailViewController
      let indexPath = sender as! IndexPath
      let searchResult = searchResults[indexPath.row]
      detailViewController.searchResult = searchResult
    }
  }
  
  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    
    switch newCollection.verticalSizeClass {
    case .compact:
      showLandscape(with: coordinator)
    case .regular, .unspecified:
      hideLandscape(with: coordinator)
    }
  }
  
  @IBAction func segmentChanged(_ sender: UISegmentedControl) {
    performSearch()
  }
  
  func iTunesUrl(searchText: String, category: Int) -> URL {
    let entityName: String
    
    switch category {
    case 1: entityName = "musicTrack"
    case 2: entityName = "software"
    case 3: entityName = "ebook"
    default: entityName = ""
    }
    
    let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200&entity=%@",
                           escapedSearchText, entityName)
    let url = URL(string: urlString)
    return url!
  }
  
  func parse(json data: Data) -> [String: Any]? {
    do {
      return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    } catch {
      print("JSON Error: '\(error)'")
      return nil
    }
  }
  
  func parse(dictionary: [String: Any]) -> [SearchResult] {
    guard let array = dictionary["results"] as? [Any] else {
      print("Expected 'results' array")
      return []
    }
    
    var searchResults: [SearchResult] = []
    
    for resultDict in array {
      if let resultDict = resultDict as? [String: Any] {
        var searchResult: SearchResult?
        
        if let wrapperType = resultDict["wrapperType"] as? String {
          switch wrapperType {
          case "track":
            searchResult = parse(track: resultDict)
          case "audiobook":
            searchResult = parse(audiobook: resultDict)
          case "software":
            searchResult = parse(software: resultDict)
          default:
            break
          }
        } else if let kind = resultDict["kind"] as? String, kind == "ebook" {
          searchResult = parse(ebook: resultDict)
        }
        
        if let result = searchResult {
          searchResults.append(result)
        }
      }
    }
    
    return searchResults
  }
  
  func parse(track dictionary: [String: Any]) -> SearchResult {
    let searchResult = SearchResult()
    
    searchResult.name = dictionary["trackName"] as! String
    searchResult.artistName = dictionary["artistName"] as! String
    searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
    searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
    searchResult.storeUrl = dictionary["trackViewUrl"] as! String
    searchResult.kind = dictionary["kind"] as! String
    searchResult.currency = dictionary["currency"] as! String
    
    if let price = dictionary["trackPrice"] as? Double {
      searchResult.price = price
    }
    
    if let genre = dictionary["primaryGenreName"] as? String {
      searchResult.genre = genre
    }
    return searchResult
  }
  
  func parse(audiobook dictionary: [String: Any]) -> SearchResult {
    let searchResult = SearchResult()
    searchResult.name = dictionary["collectionName"] as! String
    searchResult.artistName = dictionary["artistName"] as! String
    searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
    searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
    searchResult.storeUrl = dictionary["collectionViewUrl"] as! String
    searchResult.kind = "audiobook"
    searchResult.currency = dictionary["currency"] as! String
    
    if let price = dictionary["collectionPrice"] as? Double {
      searchResult.price = price
    }
    if let genre = dictionary["primaryGenreName"] as? String {
      searchResult.genre = genre
    }
    return searchResult
  }
  
  func parse(software dictionary: [String: Any]) -> SearchResult {
    let searchResult = SearchResult()
    searchResult.name = dictionary["trackName"] as! String
    searchResult.artistName = dictionary["artistName"] as! String
    searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
    searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
    searchResult.storeUrl = dictionary["trackViewUrl"] as! String
    searchResult.kind = dictionary["kind"] as! String
    searchResult.currency = dictionary["currency"] as! String
    
    if let price = dictionary["price"] as? Double {
      searchResult.price = price
    }
    if let genre = dictionary["primaryGenreName"] as? String {
      searchResult.genre = genre
    }
    return searchResult
  }
  
  func parse(ebook dictionary: [String: Any]) -> SearchResult {
    let searchResult = SearchResult()
    searchResult.name = dictionary["trackName"] as! String
    searchResult.artistName = dictionary["artistName"] as! String
    searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
    searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
    searchResult.storeUrl = dictionary["trackViewUrl"] as! String
    searchResult.kind = dictionary["kind"] as! String
    searchResult.currency = dictionary["currency"] as! String
    
    if let price = dictionary["price"] as? Double {
      searchResult.price = price
    }
    if let genres: Any = dictionary["genres"] as? String {
      searchResult.genre = (genres as! [String]).joined(separator: ", ")
    }
    return searchResult
  }
  
  func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    guard landscapeViewController == nil else { return }
    
    landscapeViewController = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController")
                                                                                    as? LandscapeViewController
    
    if let controller = landscapeViewController {
      controller.view.frame = view.bounds
      view.addSubview(controller.view)
      addChildViewController(controller)
      controller.didMove(toParentViewController: self)
    }
  }
  
  func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    // TODO: - Implement hide Landscape view function
  }
  
  func showNetworkError() {
    let alert = UIAlertController(
      title: "Whoops...",
      message: "There was an error reading from the iTunes Store. Please try again.",
      preferredStyle: .alert)
    
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(action)
    
    present(alert, animated: true, completion: nil)
  }
  
  // MARK: - Memory Warning
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

extension SearchViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    performSearch()
  }
  
  func performSearch() {
    if !searchBar.text!.isEmpty {
      searchBar.resignFirstResponder()
      
      dataTask?.cancel()
      isLoading = true
      tableView.reloadData()
      
      searchResults = []
      hasSearched = true
      
      let url = iTunesUrl(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
      let session = URLSession.shared
      dataTask = session.dataTask(with: url, completionHandler: {
        data, response, error in
        if let error = error as? NSError, error.code == -999 {
          return
        } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
          if let data = data, let jsonDictionary = self.parse(json: data) {
            self.searchResults = self.parse(dictionary: jsonDictionary)
            self.searchResults.sort(by: <)
            
            DispatchQueue.main.async {
              self.isLoading = false
              self.tableView.reloadData()
            }
            return
          }
        } else {
          print("Failure! \(response)")
        }
        DispatchQueue.main.async {
          self.hasSearched = false
          self.isLoading = false
          self.tableView.reloadData()
          self.showNetworkError()
        }
      })
      dataTask?.resume()
    }
  }
  
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
}

extension SearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if isLoading {
     return 1
    } else if !hasSearched {
      return 0
    } else if searchResults.count == 0 {
      return 1
    } else {
      return searchResults.count
    }
  }
 
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {    
    
    if isLoading {
      let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell,
                                               for: indexPath)
      let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
      spinner.startAnimating()
      return cell
    } else if searchResults.count == 0 {
      return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell,
                                           for: indexPath)
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell,
                                               for: indexPath) as! SearchResultCell

      let searchResult = searchResults[indexPath.row]
      cell.configure(for: searchResult)
      return cell
    }
  }
  
}

extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    performSegue(withIdentifier: "ShowDetail", sender: indexPath)
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    if searchResults.count == 0 || isLoading {
      return nil
    } else {
      return indexPath
    }
  }
}







