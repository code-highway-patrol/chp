// core/types.ts

/**
 * A single violation pattern with its fix and verification
 */
export interface ViolationPattern {
  /** Condition that triggers a violation */
  pattern: string;
  /** Atomic action that resolves the violation */
  fix: string;
  /** Verification that the fix achieves the intent */
  satisfies: string;
}

/**
 * Reaction types when a violation is detected
 */
export type ReactionType = 'block' | 'warn' | 'auto_fix';

/**
 * A law defines intent and violation patterns
 */
export interface Law {
  /** Unique identifier for the law */
  id: string;
  /** High-level description of what the law protects */
  intent: string;
  /** Array of violation patterns */
  violations: ViolationPattern[];
  /** How to respond to violations */
  reaction: ReactionType;
}

/**
 * An action that an agent attempts
 */
export interface Action {
  /** Type of action (tool call, file operation, etc.) */
  type: string;
  /** Action payload */
  payload: unknown;
  /** Context (file path, environment, etc.) */
  context?: Record<string, unknown>;
}

/**
 * Result of evaluating an action against laws
 */
export interface EvaluationResult {
  /** Whether the action was blocked */
  blocked?: boolean;
  /** Whether a warning was issued */
  warned?: boolean;
  /** Whether an auto-fix was applied */
  fixed?: boolean;
  /** ID of the law that was triggered */
  law?: string;
  /** Reason for the violation */
  reason?: string;
  /** Suggested fix */
  fix?: string;
  /** Human-readable suggestion */
  suggestion?: string;
  /** Applied fix (for auto_fix) */
  applied?: string;
}

/**
 * Hook types that CHP can register with
 */
export type HookType = 'pre-tool' | 'post-tool' | 'pre-commit' | 'pre-push' | 'file-change';

/**
 * Available environment capabilities
 */
export interface EnvironmentCapabilities {
  /** Git is available */
  git: boolean;
  /** Tool hooks are available */
  toolHooks: boolean;
  /** File watching is available */
  fileWatching: boolean;
}
