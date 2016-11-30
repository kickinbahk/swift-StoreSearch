//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Josiah Mory on 11/28/16.
//  Copyright © 2016 kickinbahk Productions. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
  
  private var firstTime = true
  private var downloadTasks = [URLSessionDownloadTask]()
  var searchResults = [SearchResult]()

  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var pageControl: UIPageControl!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    


    view.removeConstraints(view.constraints)
    view.translatesAutoresizingMaskIntoConstraints = true
    
    pageControl.removeConstraints(pageControl.constraints)
    pageControl.translatesAutoresizingMaskIntoConstraints = true
    
    scrollView.removeConstraints(scrollView.constraints)
    scrollView.translatesAutoresizingMaskIntoConstraints = true
    
    scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
    
    pageControl.numberOfPages = 0

  }
  
  override func viewWillLayoutSubviews() {
   super.viewWillLayoutSubviews()
    
    scrollView.frame = view.bounds
    
    pageControl.frame = CGRect(x: 0,
                               y: view.frame.size.height - pageControl.frame.size.height,
                               width: view.frame.size.width,
                               height: pageControl.frame.size.height)
    
    if firstTime {
      firstTime = false
      tileButtons(searchResults)
    }
  }

  private func tileButtons(_ searchResults: [SearchResult]) {
    var columnsPerPage = 5
    var rowsPerPage = 3
    var itemWidth: CGFloat = 96
    var itemHeight: CGFloat = 88
    var marginX: CGFloat = 0
    var marginY: CGFloat = 20
    var row = 0
    var column = 0
    var x = marginX
    
    let buttonWidth: CGFloat = 82
    let buttonHeight: CGFloat = 82
    let paddingHorz = (itemWidth - buttonWidth) / 2
    let paddingVert = (itemHeight - buttonHeight) / 2

    
    let scrollViewWidth = scrollView.bounds.size.width
    
    switch scrollViewWidth {
    case 568:
      columnsPerPage = 6
      itemWidth = 94
      marginX = 2
      
    case 667:
      columnsPerPage = 7
      itemWidth = 95
      itemHeight = 98
      marginX = 1
      marginY = 29
      
    case 736:
      columnsPerPage = 8
      rowsPerPage = 4
      itemWidth = 92
      
    default:
      break
    }
    
    let buttonsPerPage = columnsPerPage * rowsPerPage
    let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
    
    for (index, SearchResult) in searchResults.enumerated() {
      let button = UIButton(type: .custom)
      button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
      button.frame = CGRect(x: x + paddingHorz,
                            y: marginY + CGFloat(row) * itemHeight + paddingVert,
                            width: buttonWidth,
                            height: buttonHeight)
      
      downloadImage(for: SearchResult, andPlaceOn: button)
      
      scrollView.addSubview(button)
      row += 1
      
      if row == rowsPerPage {
        row = 0
        x += itemWidth
        column += 1
        if column == columnsPerPage {
          column = 0
          x += marginX * 2
        }
      }
    }
    
    scrollView.contentSize = CGSize(width: CGFloat(numPages) * scrollViewWidth,
                                    height: scrollView.bounds.size.height)
    
    print("Number of pages: \(numPages)")
    
    pageControl.numberOfPages = numPages
    pageControl.currentPage = 0
  }
  
  private func downloadImage(for searchResult: SearchResult,
                             andPlaceOn button: UIButton) {
    if let url = URL(string: searchResult.artworkSmallUrl) {
      let downloadTask = URLSession.shared.downloadTask(with: url) {
        [weak button] url, response, error in
        if error == nil, let url = url,
          let data = try? Data(contentsOf: url),
          let image = UIImage(data: data) {
          DispatchQueue.main.async {
            if let button = button {
              button.setImage(image, for: .normal)
            }
          }
        }
      }
      downloadTask.resume()
      downloadTasks.append(downloadTask)
    }
  }
  
  deinit {
    print("deinit \(self)")
    for task in downloadTasks {
      task.cancel()
    }
  }

  
  // MARK: - Memory Warning
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension LandscapeViewController: UIScrollViewDelegate {
  
  @IBAction func pageChanged(_ sender: UIPageControl) {
    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut],
                   animations: {
                    self.scrollView.contentOffset = CGPoint(
                      x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage),
                      y: 0)
                  }, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let width = scrollView.bounds.size.width
    let currentPage = Int((scrollView.contentOffset.x + width / 2) / width)
    
    pageControl.currentPage = currentPage
  }
}
