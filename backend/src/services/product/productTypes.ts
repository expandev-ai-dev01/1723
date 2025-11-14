/**
 * @interface Product
 * @description Product entity structure
 */
export interface Product {
  idProduct: number;
  name: string;
  description: string;
  ingredients: string;
  nutritionalInfo: string | null;
  basePrice: number;
  promotionalPrice: number | null;
  currentPrice: number;
  hasPromotion: boolean;
  mainImage: string;
  imageGallery: string | null;
  averageRating: number;
  totalReviews: number;
  preparationTime: string;
  available: boolean;
  categoryName?: string;
  confectionerName: string;
  confectionerRating?: number;
}

/**
 * @interface ProductDetails
 * @description Detailed product information
 */
export interface ProductDetails extends Product {
  idConfectioner: number;
  confectionerPhoto: string | null;
  confectionerProductsSold: number;
}

/**
 * @interface Flavor
 * @description Flavor option structure
 */
export interface Flavor {
  idFlavor: number;
  name: string;
  description: string;
}

/**
 * @interface Size
 * @description Size option structure
 */
export interface Size {
  idSize: number;
  name: string;
  description: string;
  priceModifier: number;
}

/**
 * @interface Review
 * @description Product review structure
 */
export interface Review {
  idReview: number;
  customerName: string;
  rating: number;
  comment: string;
  dateCreated: Date;
}

/**
 * @interface CartItem
 * @description Cart item structure
 */
export interface CartItem {
  idCartItem: number;
  idCart: number;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  success: boolean;
}

/**
 * @interface Pagination
 * @description Pagination metadata
 */
export interface Pagination {
  totalItems: number;
  totalPages: number;
  currentPage: number;
  pageSize: number;
}

/**
 * @interface ProductListResponse
 * @description Product list response structure
 */
export interface ProductListResponse {
  products: Product[];
  pagination: Pagination;
}

/**
 * @interface ProductGetResponse
 * @description Product details response structure
 */
export interface ProductGetResponse {
  product: ProductDetails;
  flavors: Flavor[];
  sizes: Size[];
  reviews: Review[];
}
