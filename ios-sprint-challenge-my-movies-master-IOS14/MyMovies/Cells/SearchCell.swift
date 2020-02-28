//
//  SearchCell.swift
//  MyMovies
//
//  Created by Ufuk Türközü on 28.02.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

protocol AddMovieDelegate {
    func addMovie(movie: MovieRepresentation)
}

class SearchCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var addButton: UIButton!
    
    var delegate: AddMovieDelegate?
    
    var movieRep: MovieRepresentation? {
        didSet {
            updateViews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func updateViews() {
        guard let movie = movieRep else {
            return
        }
        
        titleLabel.text = movie.title
    }
    
    @IBAction func addTapped(_ sender: Any) {
        guard let movie = movieRep else {
            return
        }
        
        var added: Bool = false
        
        added.toggle()
        
        if added {
            addButton.setTitle("Added", for: .normal)
        } else {
            addButton.setTitle("Add", for: .normal)
        }
        
        delegate?.addMovie(movie: movie)
    }
}
