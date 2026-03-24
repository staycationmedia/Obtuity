import { supabase } from '../config/database.js';

let marginRulesCache = null;
let cacheTimestamp = null;
const CACHE_TTL_MS = 60000;

export async function loadMarginRules() {
  const now = Date.now();

  if (marginRulesCache && cacheTimestamp && (now - cacheTimestamp < CACHE_TTL_MS)) {
    return marginRulesCache;
  }

  const { data: rules, error } = await supabase
    .from('rules_margins')
    .select('*')
    .eq('active', true)
    .order('priority', { ascending: false });

  if (error) {
    console.error('Error loading margin rules:', error);
    return marginRulesCache || [];
  }

  marginRulesCache = rules;
  cacheTimestamp = now;

  return rules;
}

export async function applyMargin(payout, params) {
  const rules = await loadMarginRules();

  const { country, partnerId, publisherId } = params;

  let applicableRule = null;

  for (const rule of rules) {
    if (rule.rule_type === 'geo+partner') {
      if (rule.geo === country && rule.partner_id === partnerId) {
        applicableRule = rule;
        break;
      }
    } else if (rule.rule_type === 'geo') {
      if (rule.geo === country && !applicableRule) {
        applicableRule = rule;
      }
    } else if (rule.rule_type === 'publisher') {
      if (rule.publisher_id === publisherId && !applicableRule) {
        applicableRule = rule;
      }
    } else if (rule.rule_type === 'partner') {
      if (rule.partner_id === partnerId && !applicableRule) {
        applicableRule = rule;
      }
    } else if (rule.rule_type === 'global') {
      if (!applicableRule) {
        applicableRule = rule;
      }
    }
  }

  if (!applicableRule) {
    return {
      rawPayout: payout,
      marginApplied: 0,
      netPayout: payout
    };
  }

  const marginPercent = parseFloat(applicableRule.margin_percent);
  const marginApplied = payout * (marginPercent / 100);
  const netPayout = payout - marginApplied;

  return {
    rawPayout: payout,
    marginApplied,
    netPayout: Math.max(0, netPayout),
    ruleId: applicableRule.id,
    ruleType: applicableRule.rule_type
  };
}

export function clearMarginCache() {
  marginRulesCache = null;
  cacheTimestamp = null;
}
