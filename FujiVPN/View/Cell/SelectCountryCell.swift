//
//  SelectCountryCell.swift
//  FujiVPN
//
//  Created by Евгений Алещенко on 13.09.2020.
//

import UIKit

protocol SelectCountryCellDelegate: AnyObject {
    func favoriteAction(_ country: Country)
}

class SelectCountryCell: UITableViewCell {
    @IBOutlet weak var countryImage: UIImageView!
    @IBOutlet weak var countryFavorite: UIImageView!
    @IBOutlet weak var countryAvailability: UIImageView!
    @IBOutlet weak var countryPremium: UIImageView!
    @IBOutlet weak var countryName: UILabel!
    
    weak var delegate: SelectCountryCellDelegate?
    
    private var country: Country!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        countryFavorite.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleFavoriteTap(_:))))
    }
    
    @objc func handleFavoriteTap(_ sender: UITapGestureRecognizer) {
        delegate?.favoriteAction(country)
    }
    
    func setCountry(_ country: Country) {
        self.country = country
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countryName.text = ""
    }
}
