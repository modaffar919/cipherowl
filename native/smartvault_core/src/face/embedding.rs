//! Face embedding comparison using Cosine Similarity.
//!
//! Designed for 128-dimensional MobileFaceNet embeddings produced by
//! Google ML Kit Face Detection on-device.
//!
//! Algorithm:
//!   similarity(a, b) = dot(a, b) / (||a|| * ||b||)
//!
//! Threshold guidance (MobileFaceNet 128D):
//!   > 0.85  → very likely same person
//!   > 0.75  → probably same person (recommended for unlock)
//!   > 0.65  → possibly same person
//!   < 0.65  → different people

/// Expected embedding dimension (MobileFaceNet output).
pub const EMBEDDING_DIM: usize = 128;

/// Default similarity threshold for "same person" verdict.
/// Tuned for MobileFaceNet 128D — adjust via settings if needed.
pub const DEFAULT_THRESHOLD: f32 = 0.75;

/// Errors for embedding operations.
#[derive(Debug, PartialEq)]
pub enum EmbeddingError {
    WrongDimension { expected: usize, got: usize },
    ZeroNorm,
}

impl std::fmt::Display for EmbeddingError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EmbeddingError::WrongDimension { expected, got } => {
                write!(f, "Wrong embedding dimension: expected {expected}, got {got}")
            }
            EmbeddingError::ZeroNorm => write!(f, "Embedding has zero norm (all-zero vector)"),
        }
    }
}

/// Compute the L2 norm of an embedding vector.
#[inline]
fn l2_norm(v: &[f32]) -> f32 {
    v.iter().map(|x| x * x).sum::<f32>().sqrt()
}

/// L2-normalise an embedding in place so ||v|| = 1.0.
/// Returns an error if the vector is all zeros.
pub fn normalize(embedding: &mut [f32; EMBEDDING_DIM]) -> Result<(), EmbeddingError> {
    let norm = l2_norm(embedding);
    if norm < f32::EPSILON {
        return Err(EmbeddingError::ZeroNorm);
    }
    for x in embedding.iter_mut() {
        *x /= norm;
    }
    Ok(())
}

/// Normalize a heap-allocated embedding (Vec<f32>) into a fixed-size array.
/// Returns `EmbeddingError::WrongDimension` if length ≠ EMBEDDING_DIM.
pub fn to_normalized_array(v: &[f32]) -> Result<[f32; EMBEDDING_DIM], EmbeddingError> {
    if v.len() != EMBEDDING_DIM {
        return Err(EmbeddingError::WrongDimension {
            expected: EMBEDDING_DIM,
            got: v.len(),
        });
    }
    let mut arr = [0f32; EMBEDDING_DIM];
    arr.copy_from_slice(v);
    normalize(&mut arr)?;
    Ok(arr)
}

/// Compute cosine similarity between two **pre-normalised** embeddings.
///
/// Both inputs must already be L2-normalised (||a|| = ||b|| = 1).
/// Result is in [-1.0, 1.0]; for face embeddings typically [0, 1].
#[inline]
pub fn cosine_similarity_normalised(a: &[f32; EMBEDDING_DIM], b: &[f32; EMBEDDING_DIM]) -> f32 {
    a.iter().zip(b.iter()).map(|(x, y)| x * y).sum()
}

/// Compute cosine similarity between two raw (not necessarily normalised) embeddings.
/// Handles normalisation internally. Returns an error if either vector is zero.
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> Result<f32, EmbeddingError> {
    if a.len() != EMBEDDING_DIM {
        return Err(EmbeddingError::WrongDimension { expected: EMBEDDING_DIM, got: a.len() });
    }
    if b.len() != EMBEDDING_DIM {
        return Err(EmbeddingError::WrongDimension { expected: EMBEDDING_DIM, got: b.len() });
    }
    let norm_a = l2_norm(a);
    let norm_b = l2_norm(b);
    if norm_a < f32::EPSILON || norm_b < f32::EPSILON {
        return Err(EmbeddingError::ZeroNorm);
    }
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    Ok(dot / (norm_a * norm_b))
}

/// Returns `true` if the cosine similarity between `a` and `b` is ≥ `threshold`.
/// Uses `DEFAULT_THRESHOLD` when `threshold` is `None`.
pub fn is_same_person(a: &[f32], b: &[f32], threshold: Option<f32>) -> Result<bool, EmbeddingError> {
    let score = cosine_similarity(a, b)?;
    Ok(score >= threshold.unwrap_or(DEFAULT_THRESHOLD))
}

/// Compare a probe embedding against a list of stored embeddings.
/// Returns the index and score of the best match, or `None` if the list is empty.
///
/// Useful for 1-to-N identification.
pub fn find_best_match(probe: &[f32], stored: &[Vec<f32>]) -> Result<Option<(usize, f32)>, EmbeddingError> {
    if stored.is_empty() {
        return Ok(None);
    }
    let mut best_idx = 0usize;
    let mut best_score = f32::NEG_INFINITY;
    for (i, s) in stored.iter().enumerate() {
        let score = cosine_similarity(probe, s)?;
        if score > best_score {
            best_score = score;
            best_idx = i;
        }
    }
    Ok(Some((best_idx, best_score)))
}

// ─── Unit tests ──────────────────────────────────────────────────────────────
#[cfg(test)]
mod tests {
    use super::*;

    fn make_embedding(val: f32) -> Vec<f32> {
        vec![val; EMBEDDING_DIM]
    }

    #[test]
    fn test_identical_embeddings_score_one() {
        let a = make_embedding(1.0);
        let score = cosine_similarity(&a, &a).unwrap();
        assert!((score - 1.0).abs() < 1e-5, "identical embeddings should score ~1.0, got {score}");
    }

    #[test]
    fn test_opposite_embeddings_score_minus_one() {
        let a = make_embedding(1.0);
        let b = make_embedding(-1.0);
        let score = cosine_similarity(&a, &b).unwrap();
        assert!((score - (-1.0)).abs() < 1e-5, "opposite embeddings should score ~-1.0, got {score}");
    }

    #[test]
    fn test_orthogonal_embeddings_score_zero() {
        // Create two orthogonal 128D vectors
        let mut a = vec![0.0f32; EMBEDDING_DIM];
        let mut b = vec![0.0f32; EMBEDDING_DIM];
        // a = [1,0,1,0,...] b = [0,1,0,1,...]
        for i in 0..EMBEDDING_DIM {
            if i % 2 == 0 { a[i] = 1.0; } else { b[i] = 1.0; }
        }
        let score = cosine_similarity(&a, &b).unwrap();
        assert!(score.abs() < 1e-5, "orthogonal embeddings should score ~0.0, got {score}");
    }

    #[test]
    fn test_wrong_dimension_error() {
        let a = vec![1.0f32; 64]; // wrong dim
        let b = make_embedding(1.0);
        assert_eq!(
            cosine_similarity(&a, &b),
            Err(EmbeddingError::WrongDimension { expected: 128, got: 64 })
        );
    }

    #[test]
    fn test_zero_norm_error() {
        let a = vec![0.0f32; EMBEDDING_DIM];
        let b = make_embedding(1.0);
        assert_eq!(cosine_similarity(&a, &b), Err(EmbeddingError::ZeroNorm));
    }

    #[test]
    fn test_is_same_person_true() {
        // Same person: high similarity
        let a = make_embedding(1.0);
        let mut b = make_embedding(1.0);
        // Slightly perturb b
        b[0] = 1.1;
        assert!(is_same_person(&a, &b, Some(0.99)).unwrap());
    }

    #[test]
    fn test_is_same_person_false() {
        // Different directions → low similarity
        let mut a = vec![0.0f32; EMBEDDING_DIM];
        let mut b = vec![0.0f32; EMBEDDING_DIM];
        a[0] = 1.0;
        b[1] = 1.0;
        assert!(!is_same_person(&a, &b, Some(0.5)).unwrap());
    }

    #[test]
    fn test_normalize_produces_unit_vector() {
        let raw = vec![3.0f32; EMBEDDING_DIM];
        let arr = to_normalized_array(&raw).unwrap();
        let norm: f32 = arr.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 1e-5, "normalized vector should have ||v||=1, got {norm}");
    }

    #[test]
    fn test_normalize_zero_returns_error() {
        let raw = vec![0.0f32; EMBEDDING_DIM];
        assert_eq!(to_normalized_array(&raw), Err(EmbeddingError::ZeroNorm));
    }

    #[test]
    fn test_cosine_similarity_symmetry() {
        let a = make_embedding(1.0);
        let b = make_embedding(0.5);
        let ab = cosine_similarity(&a, &b).unwrap();
        let ba = cosine_similarity(&b, &a).unwrap();
        assert!((ab - ba).abs() < 1e-6, "cosine similarity must be symmetric");
    }

    #[test]
    fn test_find_best_match_empty_returns_none() {
        let probe = make_embedding(1.0);
        let result = find_best_match(&probe, &[]).unwrap();
        assert!(result.is_none());
    }

    #[test]
    fn test_find_best_match_selects_closest() {
        let probe = make_embedding(1.0);
        // Build a vector orthogonal to [1,1,...,1]: alternating [1,-1,1,-1,...]
        // dot([1,1,...,1], [1,-1,1,-1,...]) = 64×1 + 64×(-1) = 0
        let mut ortho = vec![0.0f32; EMBEDDING_DIM];
        for i in (0..EMBEDDING_DIM).step_by(2) { ortho[i] = 1.0; }
        for i in (1..EMBEDDING_DIM).step_by(2) { ortho[i] = -1.0; }

        let stored = vec![
            ortho,               // index 0: orthogonal → score ≈ 0
            make_embedding(1.0), // index 1: identical  → score = 1.0
            make_embedding(-1.0),// index 2: opposite   → score = -1.0
        ];
        let (best_idx, best_score) = find_best_match(&probe, &stored).unwrap().unwrap();
        assert_eq!(best_idx, 1);
        assert!((best_score - 1.0).abs() < 1e-5, "best score should be ~1.0, got {best_score}");
    }

    #[test]
    fn test_score_range_is_valid() {
        // Generate random-ish embeddings and verify scores are in [-1, 1]
        let mut a = vec![0.0f32; EMBEDDING_DIM];
        let mut b = vec![0.0f32; EMBEDDING_DIM];
        for i in 0..EMBEDDING_DIM {
            a[i] = (i as f32 * 0.01).sin();
            b[i] = (i as f32 * 0.03).cos();
        }
        let score = cosine_similarity(&a, &b).unwrap();
        assert!(score >= -1.0 && score <= 1.0, "score {score} out of [-1, 1]");
    }

    #[test]
    fn test_default_threshold_same_person() {
        // Two nearly-identical embeddings should pass default threshold
        let a = make_embedding(1.0);
        let mut b = make_embedding(1.0);
        b[0] = 0.99; // tiny perturbation
        assert!(is_same_person(&a, &b, None).unwrap());
    }
}
