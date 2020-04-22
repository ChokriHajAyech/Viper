
import Foundation

protocol TimelineBusinessLogic {
    func fetchFromProducts(with request: TimelineModels.FetchFromProducts.Request)
    func searchCategory(with request: TimelineModels.FetchFromFiltredCategory.Request)
}

protocol TimeLineDataStore {
    var products: [TimelineModels.FetchFromProducts.Response.Product]? { get  set }
}

class TimelineInteractor: TimelineBusinessLogic, TimeLineDataStore {
  
    var products: [TimelineModels.FetchFromProducts.Response.Product]?
    var worker: TimelineWorker? = TimelineWorker()
    var presenter: TimelinePresentationLogic?
    
    func fetchFromProducts(with request: TimelineModels.FetchFromProducts.Request) {
        var listingsArray = [TimelineModels.FetchFromListings.Response.Listing]()
        var cartegoriesArray = [TimelineModels.FetchFromCategories.Response.Categroy]()
        
        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.queue.Concurrent", attributes: .concurrent)
        
        group.enter()
        concurrentQueue.async(group: group) {
            self.worker?.fetchListings(completion: { (response, error) in
                if let listings = response {
                   
                    listings.forEach({ (value) in
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .long
                        dateFormatter.locale = Locale(identifier: "en_US")
                        dateFormatter.timeZone = NSTimeZone(name: "GMT") as TimeZone?
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let stringDate: String = value.creationDate!
                        let date = dateFormatter.date(from: stringDate)
                        
                        let listing = TimelineModels.FetchFromListings.Response.Listing(categoryId: value.categoryId, listingTitle: value.title, listingPrice: value.price, isUrgent: value.isUrgent, listingId: value.id, listingSmallUrlImage: value.smallUrlImage, listingThumbUrlImage: value.thumbUrlImage, listingCreationDate: date)
                        
                        listingsArray.append(listing)
                    })
                }
                group.leave()
            })
        }
        
        group.enter()
        concurrentQueue.async(group: group) {
            self.worker?.fetchCategories(completion: { (response, error) in
                if let categories = response {
                    categories.forEach({ (value) in
                        let category = TimelineModels.FetchFromCategories.Response.Categroy(id: value.id, name: value.name)
                        cartegoriesArray.append(category)
                    })
                }
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global()) {
            var productArray = [TimelineModels.FetchFromProducts.Response.Product]()
            listingsArray.forEach { (listing) in
                if let category = cartegoriesArray.first(where: { $0.id == listing.categoryId }) {
                    let listing = TimelineModels.FetchFromProducts.Response.Listing(categoryId: category.id,listingTitle: listing.listingTitle, listingPrice: listing.listingPrice, isUrgent: listing.isUrgent, listingId: listing.listingId, listingSmallUrlImage: listing.listingSmallUrlImage, listingThumbUrlImage: listing.listingThumbUrlImage, listingCreationDate: listing.listingCreationDate)
                    let product = TimelineModels.FetchFromProducts.Response.Product(listing: listing, categoryName: category.name)
                    productArray.append(product)
                }
            }
          
            self.products = productArray
            
            let response = TimelineModels.FetchFromProducts.Response(productArray: productArray)
            self.presenter?.presentFetchProducts(with: response)
        }
    }
    
    func searchCategory(with request: TimelineModels.FetchFromFiltredCategory.Request) {
        
        var filtredCategoryProducts = [TimelineModels.FetchFromFiltredCategory.Response.Category]()
        let categoryName = request.categoryName
        
        let tmpProducts = products?.filter { ($0.categoryName?.contains(categoryName))! }
       
        let groupedProducts = Dictionary(grouping: tmpProducts!, by: { $0.categoryName! })
     
        groupedProducts.forEach { (categoryId, arrayProducts) in
            if arrayProducts.count > 0 {
               
                let categoryName = arrayProducts[0].categoryName
                
                let category = TimelineModels.FetchFromFiltredCategory.Response.Category(categoryName: categoryName!, filtredCategoryProducts: arrayProducts)
                filtredCategoryProducts.append(category)
            }
        }

        let response = TimelineModels.FetchFromFiltredCategory.Response(filtredCategory: filtredCategoryProducts)
       self.presenter?.presentSearchedCategroy(with: response)

      }
      
  
}

