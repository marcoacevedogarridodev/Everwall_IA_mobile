export interface Pixel {
  id: number;
  x: number;
  y: number;
  access_code: string;
  search_code: string;
  display_code: string;
  main_image: string | null;
  additional_images: string[];
  owner_name: string;
  owner_email: string;
  owner_message: string;
  status: 'available' | 'reserved' | 'sold' | 'pending_payment';
  moderation_status: 'pending' | 'approved' | 'rejected';
  views_count: number;
  shares_count: Record<string, number>;
  purchased_at: string;
  created_at: string;
  updated_at: string;
  amount_usd: string | null;
  amount_clp: number | null;
  payment_currency: 'USD' | 'CLP' | null;
}

export interface GridStatus {
  total_pixels: number;
  sold_pixels: number;
  available_pixels: number;
  reserved_pixels: number;
  pending_pixels: number;
  grid_width: number;
  grid_height: number;
  pixel_price_usd: string;
  pixel_price_clp: number;
}

export interface GridStats {
  total_pixels: number;
  sold_pixels: number;
  total_views: number;
  total_revenue_usd: string;
  total_revenue_clp: number;
  recent_purchases: number;
}

export interface PurchaseSession {
  session_id: string;
  pixel_x: number;
  pixel_y: number;
  images_data: string[];
  owner_email: string;
  owner_name: string;
  owner_message: string;
  payment_intent_id: string | null;
  expires_at: string;
}

export interface CreatePurchaseResponse {
  session_id: string;
  pixel_x: number;
  pixel_y: number;
  payment_intent_id: string;
  client_secret: string;
  amount_usd: string;
  amount_clp: number;
}

export interface SearchPixelRequest {
  code: string;
}

export interface SearchPixelResponse {
  found: boolean;
  pixel: Pixel | null;
  message?: string;
}
