//
//  MyMovieCell.swift
//  MyMovies
//
//  Created by Ufuk Türközü on 28.02.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

protocol ToggleSeenDelegate {
    func toggleSeen(movie: Movie)
}

class MyMovieCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seenButton: UIButton!
    
    var movie: Movie? {
        didSet {
            updateViews()
        }
    }
    
    var delegate: ToggleSeenDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func updateViews() {
        guard let movie = movie else {
            return
        }
        
        titleLabel.text = movie.title
        
        if movie.hasWatched == true {
            seenButton.setTitle("Watched", for: .normal)
        } else {
            seenButton.setTitle("Not Watched", for: .normal)
        }
    }
    
    @IBAction func seenTapped(_ sender: Any) {
        guard let movie = movie else { return }
        delegate?.toggleSeen(movie: movie)
    }
}
