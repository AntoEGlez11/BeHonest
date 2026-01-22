export interface Rating {
    id?: string;
    business_id: string;
    user_id: string;
    is_honest: boolean; // Binary rating: True = Honest, False = Dishonest
    comment?: string;
    evidence_url?: string;
    created_at?: string;
}
