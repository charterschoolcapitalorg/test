/**********************************************************
@class            QueryUtil
@brief            Builder pattern query utility for constructing dynamic SOQL queries
@testclass        QueryUtilTest
@bug              None
@todo             None
@version          V1.0
@author           Brendan Conniff
@date             8/23/19
@copyright        (c)2019 Fortimize.  All Rights Reserved. Unauthorized use is prohibited.
***********************************************************/
public class QueryUtil {
    // regex patterns for verifying different values
    private static final Pattern RE_IDENT = Pattern.compile('\\w+$');
    private static final Pattern RE_DOTTED_IDENT = Pattern.compile('\\w+([.]\\w+)*$');
    private static final Pattern RE_AGGREGATE = Pattern.compile('^\\w+\\(\\w+([.]?\\w+)*\\)\\s+\\w+$');

    // some literal constants
    private static final QueryValue LIT_NULL = new QueryNullValue();
    private static final QueryValue LIT_TRUE = new QueryBooleanValue(true);
    private static final QueryValue LIT_FALSE = new QueryBooleanValue(false);

    // some special conditions
    private static final QueryCondition COND_FALSE = new QueryAlwaysFalseCondition();
    private static final QueryCondition COND_TRUE = new QueryAlwaysTrueCondition();

    // basic binary operators for use in the WHERE clause
    private static final QueryBinaryOperator OP_EQ = new QueryBinaryOperator('=');
    private static final QueryBinaryOperator OP_NOT_EQ = new QueryBinaryOperator('!=');
    private static final QueryBinaryOperator OP_LT = new QueryBinaryOperator('<');
    private static final QueryBinaryOperator OP_GT = new QueryBinaryOperator('>');
    private static final QueryBinaryOperator OP_LE = new QueryBinaryOperator('<=');
    private static final QueryBinaryOperator OP_GE = new QueryBinaryOperator('>=');
    private static final QueryBinaryOperator OP_LIKE = new QueryBinaryOperator(' LIKE ');
    private static final QueryBinaryOperator OP_IN = new QueryBinaryOperator(' IN ');
    private static final QueryBinaryOperator OP_NOT_IN = new QueryBinaryOperator(' NOT IN ');
    private static final QueryBinaryOperator OP_INCL = new QueryBinaryOperator(' INCLUDES ');
    private static final QueryBinaryOperator OP_EXCL = new QueryBinaryOperator(' EXCLUDES ');

    // basic list operators for use in the WHERE clause
    private static final QueryListOperator OP_AND = new QueryListOperator(' AND ');
    private static final QueryListOperator OP_OR = new QueryListOperator(' OR ');

    // date literal expressions for use in the WHERE clause
    public static final QueryDateExpressionValue YESTERDAY = new QueryDateExpressionValue('YESTERDAY');
    public static final QueryDateExpressionValue TODAY = new QueryDateExpressionValue('TODAY');
    public static final QueryDateExpressionValue TOMORROW = new QueryDateExpressionValue('TOMORROW');
    public static final QueryDateExpressionValue LAST_WEEK = new QueryDateExpressionValue('LAST_WEEK');
    public static final QueryDateExpressionValue THIS_WEEK = new QueryDateExpressionValue('THIS_WEEK');
    public static final QueryDateExpressionValue NEXT_WEEK = new QueryDateExpressionValue('NEXT_WEEK');
    public static final QueryDateExpressionValue LAST_MONTH = new QueryDateExpressionValue('LAST_MONTH');
    public static final QueryDateExpressionValue THIS_MONTH = new QueryDateExpressionValue('THIS_MONTH');
    public static final QueryDateExpressionValue NEXT_MONTH = new QueryDateExpressionValue('NEXT_MONTH');
    public static final QueryDateExpressionValue LAST_90_DAYS = new QueryDateExpressionValue('LAST_90_DAYS');
    public static final QueryDateExpressionValue NEXT_90_DAYS = new QueryDateExpressionValue('NEXT_90_DAYS');
    public static final QueryDateExpressionValue THIS_QUARTER = new QueryDateExpressionValue('THIS_QUARTER');
    public static final QueryDateExpressionValue LAST_QUARTER = new QueryDateExpressionValue('LAST_QUARTER');
    public static final QueryDateExpressionValue NEXT_QUARTER = new QueryDateExpressionValue('NEXT_QUARTER');
    public static final QueryDateExpressionValue THIS_YEAR = new QueryDateExpressionValue('THIS_YEAR');
    public static final QueryDateExpressionValue LAST_YEAR = new QueryDateExpressionValue('LAST_YEAR');
    public static final QueryDateExpressionValue NEXT_YEAR = new QueryDateExpressionValue('NEXT_YEAR');
    public static final QueryDateExpressionValue THIS_FISCAL_QUARTER = new QueryDateExpressionValue('THIS_FISCAL_QUARTER');
    public static final QueryDateExpressionValue LAST_FISCAL_QUARTER = new QueryDateExpressionValue('LAST_FISCAL_QUARTER');
    public static final QueryDateExpressionValue NEXT_FISCAL_QUARTER = new QueryDateExpressionValue('NEXT_FISCAL_QUARTER');
    public static final QueryDateExpressionValue THIS_FISCAL_YEAR = new QueryDateExpressionValue('THIS_FISCAL_YEAR');
    public static final QueryDateExpressionValue LAST_FISCAL_YEAR = new QueryDateExpressionValue('LAST_FISCAL_YEAR');
    public static final QueryDateExpressionValue NEXT_FISCAL_YEAR = new QueryDateExpressionValue('NEXT_FISCAL_YEAR');

    private static Map<String,SObjectType> DESCRIBE {
        get {
            if (DESCRIBE == null) {
                DESCRIBE = Schema.getGlobalDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    private static Map<SObjectType,Map<String,ChildRelationship>> CHILD_RELATIONSHIP_MAP = new Map<SObjectType,Map<String,ChildRelationship>>();

    public static Set<String> selectAllForObject(String objName) {
        Map<String, Schema.SObjectField> schemaMap = DESCRIBE.get(objName).getDescribe().fields.getMap();
        Set<String> fields = new Set<String>();
        for (String s : schemaMap.keySet()) {
            fields.add(s);
        }
        return fields;
    }

    /**
     * Something that can be converted to SOQL
     */
    public interface QueryElement {
        /**
         * Convert this element to a SOQL string.
         */
        String toSoql();
    }

    /**
     * Marker interface for something that can appear in the "SELECT" clause
     */
    public interface QuerySelectable extends QueryElement {
        /**
         * Implement the visitor pattern to validate this selectable against
         * the provided queryable.
         */
        void accept(QueryQueryable validator, SObjectType contextType);
    }

    /**
     * Marker interface for something that can appear in the "FROM" clause
     */
    public interface QueryQueryable extends QueryElement {
        /**
         * Validate that the queryable is valid for the current context type.
         */
        void validate(SObjectType contextType);

        /**
         * Validate that this queryable supports the provided field.
         */
        void validate(QueryField field, SObjectType contextType);

        /**
         * Validate that this queryable supports the provided subquery.
         */
        void validate(QuerySubquery subquery, SObjectType contextType);
    }

    /**
     * Interface for conditions which can appear in the "WHERE" clause
     */
    public interface QueryCondition extends QueryElement {
        /**
         * Return true if this condition can only ever evaluate to true.
         * Used to automatically simplify queries in certain cases such as "Field__c NOT IN :emptyList"
         */
        Boolean isAlwaysTrue();

        /**
         * Return true if this condition can only ever evaluate to false.
         * Used to automatically simplify queries in certain cases such as "Field__c IN :emptyList"
         */
        Boolean isAlwaysFalse();
    }

    /**
     * Marker interface for something that can be ordered by.
     */
    public interface QueryOrderable extends QueryElement {
    }

    /**
     * Marker interface for literal values
     */
    public interface QueryValue extends QueryElement {
    }

    /**
     * Exception used when a value does not match the required format
     */
    public class QueryFormatException extends Exception {
    }

    /**
     * Base class for most query conditions, providing default implmentations of always false / always true
     */
    public abstract class QueryConditionBase implements QueryCondition {
        public Boolean isAlwaysFalse() {
            return false;
        }
        public Boolean isAlwaysTrue() {
            return false;
        }
    }

    /**
     * Component of a query ordering (such as "Account.ContactId ASC NULLS LAST")
     */
    public class QueryOrder implements QueryElement {
        private final QueryOrderable orderable;

        private Boolean isAscending = null;
        private Boolean isNullsFirst = null;

        public QueryOrder(QueryOrderable orderable) {
            this.orderable = orderable;
        }

        public QueryOrder ascending() {
            this.isAscending = true;
            return this;
        }

        public QueryOrder descending() {
            this.isAscending = false;
            return this;
        }

        public QueryOrder nullsFirst() {
            this.isNullsFirst = true;
            return this;
        }

        public QueryOrder nullsLast() {
            this.isNullsFirst = false;
            return this;
        }

        public String toSoql() {
            List<String> components = new List<String>();
            components.add(orderable.toSoql());
            if (this.isAscending != null) {
                components.add(this.isAscending ? 'ASC' : 'DESC');
            }
            if (this.isNullsFirst != null) {
                components.add(this.isNullsFirst ? 'NULLS FIRST' : 'NULLS LAST');
            }
            return String.join(components, ' ');
        }
    }

    /**
     * A dotted identifier for a field (such as "Account.ContactId")
     */
    public class QueryField implements QuerySelectable, QueryOrderable {
        private final String field;

        private QueryField(String field) {
            validateFormat(RE_DOTTED_IDENT, RE_AGGREGATE, field);
            this.field = field;
        }

        public String getField() {
            return this.field;
        }

        public void accept(QueryQueryable queryable, SObjectType contextType) {
            // apply visitor pattern
            queryable.validate(this, contextType);
        }

        public String toSoql() {
            return field;
        }
    }

    /**
     * A simple name of a table to query (such as "Account")
     */
    public class QueryTable implements QueryQueryable {
        private final String table;

        private QueryTable(String table) {
            validateFormat(RE_IDENT, table);
            this.table = table;
        }

        public String getTable() {
            return this.table;
        }

        private SObjectType getType(SObjectType contextType) {
            if (contextType == null) {
                return DESCRIBE.get(this.table);
            }
            ChildRelationship cr = getChildRelationship(contextType, this.table);
            return cr == null ? null : cr.getChildSObject();
        }

        public void validate(SObjectType contextType) {
            if (getType(contextType) == null) {
                if (contextType == null) {
                    throw new QueryFormatException('Not a valid object type: '+this.table);
                } else {
                    throw new QueryFormatException('Not a valid child relationship for '+contextType.getDescribe().getLocalName()+': '+this.table);
                }
            }
        }

        public void validate(QueryField field, SObjectType contextType) {
            String fieldName = field.getField();
            DescribeSObjectResult describe = getType(contextType).getDescribe();
            Map<String,SObjectField> currentFieldMap = describe.fields.getMap();

            for (String fieldPathComponent: fieldName.split('.')) {
                if (currentFieldMap == null) {
                    throw new QueryFormatException('Attempt to treat a non-relationship field as a relationship on '+describe.getLocalName()+': '+fieldName);
                }

                SObjectField sobField = currentFieldMap.get(fieldPathComponent);
                if (sobField == null) {
                    throw new QueryFormatException('Not a valid field for '+describe.getLocalName()+': '+fieldName);
                }

                List<SObjectType> referenceToTypes = sobField.getDescribe().getReferenceTo();
                if (referenceToTypes.isEmpty()) {
                    currentFieldMap = null;
                } else {
                    if (referenceToTypes.size() > 1) {
                        throw new QueryFormatException('Reference to polymorphic fields is not supported for '+describe.getLocalName()+': '+fieldName);
                    }
                    currentFieldMap = referenceToTypes.get(0).getDescribe().fields.getMap();
                }
            }
        }

        public void validate(QuerySubquery subquery, SObjectType contextType) {
            subquery.validate(getType(contextType));
        }

        public String toSoql() {
            return table;
        }
    }

    /**
     * A list operator (such as "AND", "OR")
     */
    private class QueryListOperator implements QueryElement {
        private final String operator;

        private QueryListOperator(String operator) {
            this.operator = operator;
        }

        public String toSoql() {
            return operator;
        }
    }

    /**
     * A binary operator (such as "=", "!=", "LIKE", "IN", "NOT IN")
     */
    private class QueryBinaryOperator implements QueryElement {
        private final String operator;

        private QueryBinaryOperator(String operator) {
            this.operator = operator;
        }

        public String toSoql() {
            return operator;
        }
    }

    /**
     * List conditions for combining multiple sub-conditions
     */
    private class QueryListCondition extends QueryConditionBase {
        private final QueryListOperator listOp;
        private final List<QueryCondition> conds;

        private QueryListCondition(QueryListOperator listOp, List<QueryCondition> conds) {
            this.listOp = listOp;
            this.conds = new List<QueryCondition>();

            // flatten any nested conditions using the same operator
            for (QueryCondition cond: conds) {
                if (cond instanceof QueryListCondition) {
                    QueryListCondition that = (QueryListCondition)cond;
                    if (that.listOp == this.listOp) {
                        this.conds.addAll(that.conds);
                        continue;
                    }
                }
                this.conds.add(cond);
            }
        }

        public String toSoql() {
            List<String> strs = new List<String>();
            for (QueryCondition cond : this.conds) {
                strs.add(cond.toSoql());
            }
            return strs.size() == 1
                ? strs.get(0)
                : String.format('({0})', new List<String>{ String.join(strs, this.listOp.toSoql()) });
        }
    }

    /**
     * Binary conditions comparing a field with a specific value
     */
    private class QueryNotCondition extends QueryConditionBase {
        private final QueryCondition cond;

        private QueryNotCondition(QueryCondition cond) {
            this.cond = cond;
        }

        public String toSoql() {
            return String.format('(NOT {0})', new List<String>{ cond.toSoql() });
        }
    }

    /**
     * Binary conditions comparing a field with a specific value
     */
    private class QueryBinaryCondition extends QueryConditionBase {
        private final QueryBinaryOperator binOp;
        private final QueryField field;
        private final QueryValue value;

        private QueryBinaryCondition(QueryBinaryOperator binOp, QueryField field, QueryValue value) {
            this.binOp = binOp;
            this.field = field;
            this.value = value;
        }

        public String toSoql() {
            return String.format(
                '{0}{1}{2}',
                new List<String>{ this.field.toSoql(), this.binOp.toSoql(), this.value.toSoql() }
            );
        }
    }

    /**
     * Used to stub out query conditions that should always be considered "true".
     * For example, the case where "Field NOT IN :emptyList". This condition should always be considered true,
     * however when calling toSoql this will produce an invalid syntax and result in an error: "Field NOT IN ()".
     * To avoid this error case, we mark the condition as "always true" and replace it with a condition we know
     * will always evaluate to be true ("Id != null").
     */
    private class QueryAlwaysTrueCondition implements QueryCondition {
        public Boolean isAlwaysTrue() {
            return true;
        }
        public Boolean isAlwaysFalse() {
            return false;
        }
        public String toSoql() {
            return 'Id!=null';
        }
    }

    /**
     * Used to stub out query conditions that should always be considered "false".
     * For example, the case where "Field IN :emptyList". This condition should always be considered false,
     * however when calling toSoql this will produce an invalid syntax and result in an error: "Field IN ()".
     * To avoid this error case, we mark the condition as "always false" and replace it with a condition we know
     * will always evaluate to be false ("Id = null").
     */
    private class QueryAlwaysFalseCondition implements QueryCondition {
        public Boolean isAlwaysTrue() {
            return false;
        }
        public Boolean isAlwaysFalse() {
            return true;
        }
        public String toSoql() {
            return 'Id=null';
        }
    }

    /**
     * Subqueries; can be used as a query value (such as a semi-join or anti-join) or as a selectable element (such as a
     * child relationship query)
     */
    private class QuerySubquery implements QueryValue, QuerySelectable {
        private final Query subquery;

        private QuerySubquery(Query subquery) {
            this.subquery = subquery;
        }

        public void validate(SObjectType type) {
            this.subquery.validate(type);
        }

        public void accept(QueryQueryable queryable, SObjectType contextType) {
            // apply visitor pattern
            queryable.validate(this, contextType);
        }

        public String toSoql() {
            return String.format('({0})', new List<String>{ this.subquery.toSoql() });
        }
    }

    /**
     * String literal values
     */
    public class QueryStringValue implements QueryValue {
        private final String value;

        private QueryStringValue(String value) {
            this.value = value;
        }

        public String toSoql() {
            return String.format('\'\'{0}\'\'', new List<String>{ String.escapeSingleQuotes(this.value) });
        }
    }

    /**
     * Numeric / decimal literal values
     */
    public class QueryDecimalValue implements QueryValue {
        private final Decimal value;

        private QueryDecimalValue(Decimal value) {
            this.value = value;
        }

        public String toSoql() {
            return String.valueOf(value);
        }
    }

    /**
     * List literal values
     */
    public class QueryListValue implements QueryValue {
        private final List<QueryValue> values;

        private QueryListValue(List<QueryValue> values) {
            this.values = values;
        }

        public Boolean isEmpty() {
            return values.isEmpty();
        }

        public String toSoql() {
            List<String> strs = new List<String>();
            for (QueryValue value : values) {
                strs.add(value.toSoql());
            }
            return String.format('({0})', new List<String>{ String.join(strs, ',') });
        }
    }

    /**
     * Datetime literal values (ISO GMT date/time format)
     */
    public class QueryDatetimeValue implements QueryValue {
        private final Datetime value;

        private QueryDatetimeValue(Datetime value) {
            this.value = value;
        }

        public String toSoql() {
            return String.format(
                '{0}-{1}-{2}T{3}:{4}:{5}Z',
                new List<String>{
                    String.valueOf(value.yearGmt()).leftPad(4, '0'),
                    String.valueOf(value.monthGmt()).leftPad(2, '0'),
                    String.valueOf(value.dayGmt()).leftPad(2, '0'),
                    String.valueOf(value.hourGmt()).leftPad(2, '0'),
                    String.valueOf(value.minuteGmt()).leftPad(2, '0'),
                    String.valueOf(value.secondGmt()).leftPad(2, '0')
                }
            );
        }
    }

    /**
     * Boolean literal values
     */
    public class QueryBooleanValue implements QueryValue {
        private final Boolean value;

        private QueryBooleanValue(Boolean value) {
            this.value = value;
        }

        public String toSoql() {
            return String.valueOf(value);
        }
    }

    /**
     * Date literal values (ISO date format)
     */
    public class QueryDateValue implements QueryValue {
        private final Date value;

        private QueryDateValue(Date value) {
            this.value = value;
        }

        public String toSoql() {
            return String.format(
                '{0}-{1}-{2}',
                new List<String>{
                    String.valueOf(value.year()).leftPad(4, '0'),
                    String.valueOf(value.month()).leftPad(2, '0'),
                    String.valueOf(value.day()).leftPad(2, '0')
                }
            );
        }
    }

    /**
     * Date literal expressions
     */
    public class QueryDateExpressionValue implements QueryValue {
        private final String value;

        private QueryDateExpressionValue(String value) {
            this.value = value;
        }

        public String toSoql() {
            return value;
        }
    }

    /**
     * Null literal
     */
    public class QueryNullValue implements QueryValue {
        public String toSoql() {
            return 'null';
        }
    }

    /**
     * Complete SOQL query
     */
    public class Query {
        private final List<QuerySelectable> selectables;
        private final QueryQueryable queryable;

        private QueryCondition condition;
        private List<QueryOrder> orders;

        private Integer limitValue;
        private Integer offsetValue;

        private String statement;
        private String groupBy;

        private Query(List<QuerySelectable> selectables, QueryQueryable queryable) {
            if (selectables.isEmpty()) {
                throw new QueryFormatException('You must select at least one value');
            }

            this.selectables = selectables;
            this.queryable = queryable;
        }

        public void validate() {
            validate(null);
        }

        public void validate(SObjectType contextType) {
            this.queryable.validate(contextType);
            for (QuerySelectable selectable: selectables) {
                selectable.accept(queryable, contextType);
            }
        }

        public Query withCondition(QueryCondition condition) {
            this.condition = condition;
            return this;
        }

        public Query withOrder(List<QueryOrder> orders) {
            this.orders = orders;
            return this;
        }

        public Query withOrder(QueryOrder order) {
            return withOrder(new List<QueryOrder>{ order });
        }

        public Query withOrder(QueryOrderBuilder qob) {
            return withOrder(qob.getOrders());
        }

        public Query withOrder(String field) {
            return withOrder(getOrder(field));
        }

        public Query withLimit(Integer limitValue) {
            this.limitValue = limitValue;
            return this;
        }

        public Query withOffset(Integer offsetValue) {
            this.offsetValue = offsetValue;
            return this;
        }

        public Query groupBy(String statement) {
            this.groupBy = statement;
            return this;
        }

        public String toSoql() {
            List<String> fieldNames = new List<String>();
            for (QuerySelectable field : this.selectables) {
                fieldNames.add(field.toSoql());
            }

            List<String> components = new List<String>();

            components.add(
                String.format(
                    'SELECT {0} FROM {1}',
                    new List<String>{ String.join(fieldNames, ','), this.queryable.toSoql() }
                )
            );

            if (this.condition != null && !this.condition.isAlwaysTrue()) {
                components.add(String.format('WHERE {0}', new List<String>{ condition.toSoql() }));
            }

            if (this.groupBy != null) {
                components.add(groupBy);
            }

            if (this.orders != null && !this.orders.isEmpty()) {
                List<String> strs = new List<String>();
                for (QueryOrder order : this.orders) {
                    strs.add(order.toSoql());
                }
                components.add(String.format('ORDER BY {0}', new List<String>{ String.join(strs, ',') }));
            }

            if (this.limitValue != null && this.limitValue >= 0) {
                components.add(String.format('LIMIT {0}', new List<String>{ String.valueOf(this.limitValue) }));
            }

            if (this.offsetValue != null && this.offsetValue >= 0) {
                components.add(String.format('OFFSET {0}', new List<String>{ String.valueOf(this.offsetValue) }));
            }

            if (this.statement != null) {
                components.add(statement);
            }

            return String.join(components, ' ');
        }

        public override String toString() {
            return toSoql();
        }
    }

    /**
     * Builder interface for constructing an ORDER BY clause
     */
    public class QueryOrderBuilder {
        private final List<QueryOrder> orders = new List<QueryOrder>();

        private QueryOrder currentOrder = null;

        private void validateCurrentOrder() {
            if (currentOrder == null) {
                throw new QueryFormatException('You must .orderBy a field before specifying direction');
            }
        }

        public QueryOrderBuilder orderBy(String field) {
            currentOrder = getOrder(field);
            orders.add(currentOrder);
            return this;
        }

        public QueryOrderBuilder thenBy(String field) {
            return orderBy(field);
        }

        public QueryOrderBuilder nullsFirst() {
            validateCurrentOrder();
            currentOrder.nullsFirst();
            return this;
        }

        public QueryOrderBuilder nullsLast() {
            validateCurrentOrder();
            currentOrder.nullsLast();
            return this;
        }

        public QueryOrderBuilder ascending() {
            validateCurrentOrder();
            currentOrder.ascending();
            return this;
        }

        public QueryOrderBuilder descending() {
            validateCurrentOrder();
            currentOrder.descending();
            return this;
        }

        private List<QueryOrder> getOrders() {
            return orders;
        }

        public QueryOrderBuilder parse(String orderBy) {
            if (String.isNotBlank(orderBy)) {
                for (String component: orderBy.trim().split('\\s*,\\s*')) {
                    List<String> componentDetails = component.split('\\s+');
                    this.thenBy(componentDetails.get(0));
                    for (Integer i = 1 ; i < componentDetails.size(); i++) {
                        switch on componentDetails.get(i).toLowerCase() {
                            when 'asc' { this.ascending(); }
                            when 'desc' { this.descending(); }
                            when 'nulls' { }
                            when 'first' { this.nullsFirst(); }
                            when 'last' { this.nullsLast(); }
                            when else {
                                throw new QueryFormatException('Unknown parameter for order clause: '+componentDetails.get(i));
                            }
                        }
                    }
                }
            }
            return this;
        }
    }

    /**
     * Builder interface for constructing a SELECT clause
     */
    public class QuerySelectionBuilder {
        private final Set<String> uniqueFields = new Set<String>();
        private final List<QuerySelectable> selectables = new List<QuerySelectable>();

        public QuerySelectionBuilder add(FieldSet fs) {
            for (FieldSetMember fsm: fs.getFields()) {
                add(fsm.getFieldPath());
            }
            return this;
        }

        public QuerySelectionBuilder add(Set<String> fields) {
            List<String> lst = new List<String>(fields);
            lst.sort(); // sort so we get a predictable order
            return add(lst);
        }

        public QuerySelectionBuilder add(List<String> fields) {
            for (String field : fields) {
                add(field);
            }
            return this;
        }

        public QuerySelectionBuilder add(String field) {
            if (uniqueFields.add(field.toLowerCase())) {
                selectables.add(new QueryField(field));
            }
            return this;
        }

        public QuerySelectionBuilder add(Query q) {
            selectables.add(new QuerySubquery(q));
            return this;
        }

        private List<QuerySelectable> getSelectables() {
            return selectables;
        }
    }

    private static ChildRelationship getChildRelationship(SObjectType type, String name) {
        String lcName = name.toLowerCase();
        Map<String,ChildRelationship> relMap = CHILD_RELATIONSHIP_MAP.get(type);
        if (relMap == null) {
            relMap = new Map<String,ChildRelationship>();
            for (ChildRelationship rel: type.getDescribe().getChildRelationships()) {
                relMap.put(rel.getRelationshipName().toLowerCase(), rel);
            }
            CHILD_RELATIONSHIP_MAP.put(type, relMap);
        }
        return relMap.get(lcName);
    }

    private static void validateFormat(Pattern re, String str) {
        if (!re.matcher(str).matches()) {
            throw new QueryFormatException('Invalid format: ' + str);
        }
    }

    private static void validateFormat(Pattern re1, Pattern re2, String str) {
        if (!(re1.matcher(str).matches() || re2.matcher(str).matches())) {
            throw new QueryFormatException('Invalid format: ' + str);
        }
    }

    private static QueryValue valueOf(String str) {
        return str == null ? LIT_NULL : new QueryStringValue(str);
    }

    private static QueryValue valueOf(Decimal num) {
        return num == null ? LIT_NULL : new QueryDecimalValue(num);
    }

    private static QueryValue valueOf(Date d) {
        return d == null ? LIT_NULL : new QueryDateValue(d);
    }

    private static QueryValue valueOf(Datetime dt) {
        return dt == null ? LIT_NULL : new QueryDatetimeValue(dt);
    }

    private static QueryValue valueOf(Boolean bool) {
        return bool == null ? LIT_NULL : (bool ? LIT_TRUE : LIT_FALSE);
    }

    private static QueryListValue valueOf(List<String> strs) {
        List<QueryValue> values = new List<QueryValue>();
        for (String str : strs) {
            values.add(valueOf(str));
        }
        return new QueryListValue(values);
    }

    private static QueryListValue valueOf(List<Decimal> nums) {
        List<QueryValue> values = new List<QueryValue>();
        for (Decimal num : nums) {
            values.add(valueOf(num));
        }
        return new QueryListValue(values);
    }

    private static QueryListValue valueOf(List<Date> ds) {
        List<QueryValue> values = new List<QueryValue>();
        for (Date d : ds) {
            values.add(valueOf(d));
        }
        return new QueryListValue(values);
    }

    private static QueryListValue valueOf(List<Datetime> dts) {
        List<QueryValue> values = new List<QueryValue>();
        for (Datetime dt : dts) {
            values.add(valueOf(dt));
        }
        return new QueryListValue(values);
    }

    private static QueryListValue valueOf(List<Boolean> bools) {
        List<QueryValue> values = new List<QueryValue>();
        for (Boolean bool : bools) {
            values.add(valueOf(bool));
        }
        return new QueryListValue(values);
    }

    private static Query getSelect(QuerySelectionBuilder qsb, QueryTable table) {
        return getSelect(qsb.getSelectables(), table);
    }

    private static Query getSelect(List<QuerySelectable> selectables, QueryTable table) {
        return new Query(selectables, table);
    }

    public static Query getSelect(QuerySelectionBuilder qsb, String t) {
        return getSelect(qsb, new QueryTable(t));
    }

    public static Query getSelect(String fl, String t) {
        return getSelect(buildSelection().add(fl), t);
    }

    public static Query getSelect(List<String> fls, String t) {
        return getSelect(buildSelection().add(fls), t);
    }

    public static Query getSelect(Set<String> fls, String t) {
        return getSelect(buildSelection().add(fls), t);
    }

    public static QuerySelectionBuilder buildSelection() {
        return new QuerySelectionBuilder();
    }

    private static QueryCondition binOp(QueryBinaryOperator op, String field, QueryValue value) {
        return new QueryBinaryCondition(op, new QueryField(field), value);
    }

    //
    // Null comparison operators
    //

    public static QueryCondition getIsNull(String field) {
        return binOp(OP_EQ, field, LIT_NULL);
    }
    public static QueryCondition getIsNotNull(String field) {
        return binOp(OP_NOT_EQ, field, LIT_NULL);
    }

    //
    // "Equal" operator
    //

    public static QueryCondition getEq(String field, String value) {
        return binOp(OP_EQ, field, valueOf(value));
    }
    public static QueryCondition getEq(String field, Decimal value) {
        return binOp(OP_EQ, field, valueOf(value));
    }
    public static QueryCondition getEq(String field, Date value) {
        return binOp(OP_EQ, field, valueOf(value));
    }
    public static QueryCondition getEq(String field, Datetime value) {
        return binOp(OP_EQ, field, valueOf(value));
    }
    public static QueryCondition getEq(String field, Boolean value) {
        return binOp(OP_EQ, field, valueOf(value));
    }
    public static QueryCondition getEq(String field, QueryDateExpressionValue value) {
        return binOp(OP_EQ, field, value);
    }


    //
    // "Not equal" operator
    //

    public static QueryCondition getNotEq(String field, String value) {
        return binOp(OP_NOT_EQ, field, valueOf(value));
    }
    public static QueryCondition getNotEq(String field, Decimal value) {
        return binOp(OP_NOT_EQ, field, valueOf(value));
    }
    public static QueryCondition getNotEq(String field, Date value) {
        return binOp(OP_NOT_EQ, field, valueOf(value));
    }
    public static QueryCondition getNotEq(String field, Datetime value) {
        return binOp(OP_NOT_EQ, field, valueOf(value));
    }
    public static QueryCondition getNotEq(String field, Boolean value) {
        return binOp(OP_NOT_EQ, field, valueOf(value));
    }

    //
    // "Less Than" operator
    //

    public static QueryCondition getLt(String field, Decimal value) {
        return binOp(OP_LT, field, valueOf(value));
    }
    public static QueryCondition getLt(String field, Date value) {
        return binOp(OP_LT, field, valueOf(value));
    }
    public static QueryCondition getLt(String field, Datetime value) {
        return binOp(OP_LT, field, valueOf(value));
    }
    public static QueryCondition getLt(String field, QueryDateExpressionValue value) {
        return binOp(OP_LT, field, value);
    }


    //
    // "Less Than Or Equal" operator
    //

    public static QueryCondition getLe(String field, Decimal value) {
        return binOp(OP_LE, field, valueOf(value));
    }
    public static QueryCondition getLe(String field, Date value) {
        return binOp(OP_LE, field, valueOf(value));
    }
    public static QueryCondition getLe(String field, Datetime value) {
        return binOp(OP_LE, field, valueOf(value));
    }

    //
    // "Greater Than" operator
    //

    public static QueryCondition getGt(String field, Decimal value) {
        return binOp(OP_GT, field, valueOf(value));
    }
    public static QueryCondition getGt(String field, Date value) {
        return binOp(OP_GT, field, valueOf(value));
    }
    public static QueryCondition getGt(String field, Datetime value) {
        return binOp(OP_GT, field, valueOf(value));
    }
    public static QueryCondition getGt(String field, QueryDateExpressionValue value) {
        return binOp(OP_GT, field, value);
    }

    //
    // "Greater Than Or Equal" operator
    //

    public static QueryCondition getGe(String field, Decimal value) {
        return binOp(OP_GE, field, valueOf(value));
    }
    public static QueryCondition getGe(String field, Date value) {
        return binOp(OP_GE, field, valueOf(value));
    }
    public static QueryCondition getGe(String field, Datetime value) {
        return binOp(OP_GE, field, valueOf(value));
    }

    //
    // "Like" operator
    //

    public static QueryCondition getLike(String field, String value) {
        return binOp(OP_LIKE, field, valueOf(value));
    }

    //
    // "In" operator
    //

    // wrapper to provide special handling for empty lists
    private static QueryCondition inOp(String field, QueryListValue value) {
        return value.isEmpty() ? COND_FALSE : binOp(OP_IN, field, value);
    }

    public static QueryCondition getIn(String field, List<Id> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, List<String> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, List<Decimal> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, List<Date> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, List<Datetime> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, List<Boolean> values) {
        return inOp(field, valueOf(values));
    }
    public static QueryCondition getIn(String field, Set<Id> values) {
        return getIn(field, new List<Id>(values));
    }
    public static QueryCondition getIn(String field, Set<String> values) {
        return getIn(field, new List<String>(values));
    }
    public static QueryCondition getIn(String field, Set<Decimal> values) {
        return getIn(field, new List<Decimal>(values));
    }
    public static QueryCondition getIn(String field, Set<Date> values) {
        return getIn(field, new List<Date>(values));
    }
    public static QueryCondition getIn(String field, Set<Datetime> values) {
        return getIn(field, new List<Datetime>(values));
    }
    public static QueryCondition getIn(String field, Set<Boolean> values) {
        return getIn(field, new List<Boolean>(values));
    }
    public static QueryCondition getIn(String field, Query q) {
        return binOp(OP_IN, field, new QuerySubquery(q));
    }

    //
    // "Not In" operator
    //

    // wrapper to provide special handling for empty lists
    private static QueryCondition notInOp(String field, QueryListValue value) {
        return value.isEmpty() ? COND_TRUE : binOp(OP_NOT_IN, field, value);
    }

    public static QueryCondition getNotIn(String field, List<Id> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, List<String> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, List<Decimal> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, List<Date> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, List<Datetime> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, List<Boolean> values) {
        return notInOp(field, valueOf(values));
    }
    public static QueryCondition getNotIn(String field, Set<Id> values) {
        return getNotIn(field, new List<Id>(values));
    }
    public static QueryCondition getNotIn(String field, Set<String> values) {
        return getNotIn(field, new List<String>(values));
    }
    public static QueryCondition getNotIn(String field, Set<Decimal> values) {
        return getNotIn(field, new List<Decimal>(values));
    }
    public static QueryCondition getNotIn(String field, Set<Date> values) {
        return getNotIn(field, new List<Date>(values));
    }
    public static QueryCondition getNotIn(String field, Set<Datetime> values) {
        return getNotIn(field, new List<Datetime>(values));
    }
    public static QueryCondition getNotIn(String field, Set<Boolean> values) {
        return getNotIn(field, new List<Boolean>(values));
    }
    public static QueryCondition getNotIn(String field, Query q) {
        return binOp(OP_NOT_IN, field, new QuerySubquery(q));
    }
    /*
     * INCLUDES operator
     */
    // wrapper to provide special handling for empty lists
    private static QueryCondition inclOp(String field, QueryListValue value) {
        return value.isEmpty() ? COND_FALSE : binOp(OP_INCL, field, value);
    }

    public static QueryCondition getIncludes(String field, List<String> values) {
        return inclOp(field, valueOf(values));
    }
    public static QueryCondition getIncludes(String field, Set<String> values) {
        return getIncludes(field, new List<String>(values));
    }

    //
    // "Unary Not" operator
    //

    public static QueryCondition getNot(QueryCondition cond) {
        // if the child condition is always true or false, just invert the value
        if (cond.isAlwaysFalse()) {
            return COND_TRUE;
        }
        if (cond.isAlwaysTrue()) {
            return COND_FALSE;
        }

        return new QueryNotCondition(cond);
    }

    //
    // "And" operator
    //

    public static QueryCondition getAnd(List<QueryCondition> conds) {
        if (conds.isEmpty()) {
            return COND_TRUE;
        }

        List<QueryCondition> keepConds = new List<QueryCondition>();
        for (QueryCondition cond : conds) {
            if (cond.isAlwaysFalse()) {
                // short-circuit to false if any sub-condition is always false
                return COND_FALSE;
            }
            if (!cond.isAlwaysTrue()) {
                // only consider sub-conditions that are not always true
                keepConds.add(cond);
            }
        }

        // if we didn't keep any sub-conditions, that means all sub-conditions were always true
        // and the result of the AND is also always true
        if (keepConds.isEmpty()) {
            return COND_TRUE;
        }

        return new QueryListCondition(OP_AND, conds);
    }

    //
    // "Or" operator
    //

    public static QueryCondition getOr(List<QueryCondition> conds) {
        if (conds.isEmpty()) {
            return COND_TRUE;
        }

        List<QueryCondition> keepConds = new List<QueryCondition>();
        for (QueryCondition cond : conds) {
            if (cond.isAlwaysTrue()) {
                // short-circuit to false if any sub-condition is always true
                return COND_TRUE;
            }
            if (!cond.isAlwaysFalse()) {
                // only consider sub-conditions that are not always false
                keepConds.add(cond);
            }
        }

        // if we didn't keep any sub-conditions, that means all sub-conditions were always false
        // and the result of the OR is also always false
        if (keepConds.isEmpty()) {
            return COND_FALSE;
        }

        return new QueryListCondition(OP_OR, conds);
    }

    //
    // Overloaded AND operators for convenience
    //

    public static QueryCondition getAnd(QueryCondition cond1, QueryCondition cond2) {
        return getAnd(new List<QueryCondition>{ cond1, cond2 });
    }

    public static QueryCondition getAnd(QueryCondition cond1, QueryCondition cond2, QueryCondition cond3) {
        return getAnd(new List<QueryCondition>{ cond1, cond2, cond3 });
    }

    public static QueryCondition getAnd(
        QueryCondition cond1,
        QueryCondition cond2,
        QueryCondition cond3,
        QueryCondition cond4
    ) {
        return getAnd(new List<QueryCondition>{ cond1, cond2, cond3, cond4 });
    }

    public static QueryCondition getAnd(
        QueryCondition cond1,
        QueryCondition cond2,
        QueryCondition cond3,
        QueryCondition cond4,
        QueryCondition cond5
    ) {
        return getAnd(new List<QueryCondition>{ cond1, cond2, cond3, cond4, cond5 });
    }

    //
    // Overloaded AND operators for convenience
    //

    public static QueryCondition getOr(QueryCondition cond1, QueryCondition cond2) {
        return getOr(new List<QueryCondition>{ cond1, cond2 });
    }

    public static QueryCondition getOr(QueryCondition cond1, QueryCondition cond2, QueryCondition cond3) {
        return getOr(new List<QueryCondition>{ cond1, cond2, cond3 });
    }

    public static QueryCondition getOr(
        QueryCondition cond1,
        QueryCondition cond2,
        QueryCondition cond3,
        QueryCondition cond4
    ) {
        return getOr(new List<QueryCondition>{ cond1, cond2, cond3, cond4 });
    }

    public static QueryCondition getOr(
        QueryCondition cond1,
        QueryCondition cond2,
        QueryCondition cond3,
        QueryCondition cond4,
        QueryCondition cond5
    ) {
        return getOr(new List<QueryCondition>{ cond1, cond2, cond3, cond4, cond5 });
    }

    //
    // Ordering clauses
    //

    public static QueryOrderBuilder buildOrder() {
        return new QueryOrderBuilder();
    }

    public static QueryOrder getOrder(String field) {
        return new QueryOrder(new QueryField(field));
    }

    //
    // Getters for date literal expressions with parameters (LAST_N_DAYS:n)
    //

    public static QueryDateExpressionValue getNextNDays(Integer days) { return new QueryDateExpressionValue('NEXT_N_DAYS:'+days); }
    public static QueryDateExpressionValue getLastNDays(Integer days) { return new QueryDateExpressionValue('LAST_N_DAYS:'+days); }
    public static QueryDateExpressionValue getNextNWeeks(Integer weeks) { return new QueryDateExpressionValue('NEXT_N_WEEKS:'+weeks); }
    public static QueryDateExpressionValue getLastNWeeks(Integer weeks) { return new QueryDateExpressionValue('LAST_N_WEEKS:'+weeks); }
    public static QueryDateExpressionValue getNextNMonths(Integer months) { return new QueryDateExpressionValue('NEXT_N_MONTHS:'+months); }
    public static QueryDateExpressionValue getLastNMonths(Integer months) { return new QueryDateExpressionValue('LAST_N_MONTHS:'+months); }
    public static QueryDateExpressionValue getNextNQuarters(Integer quarters) { return new QueryDateExpressionValue('NEXT_N_QUARTERS:'+quarters); }
    public static QueryDateExpressionValue getLastNQuarters(Integer quarters) { return new QueryDateExpressionValue('LAST_N_QUARTERS:'+quarters); }
    public static QueryDateExpressionValue getNextNYears(Integer years) { return new QueryDateExpressionValue('NEXT_N_YEARS:'+years); }
    public static QueryDateExpressionValue getLastNYears(Integer years) { return new QueryDateExpressionValue('LAST_N_YEARS:'+years); }
    public static QueryDateExpressionValue getNextNFiscalQuarters(Integer quarters) { return new QueryDateExpressionValue('NEXT_N_FISCAL_QUARTERS:'+quarters); }
    public static QueryDateExpressionValue getLastNFiscalQuarters(Integer quarters) { return new QueryDateExpressionValue('LAST_N_FISCAL_QUARTERS:'+quarters); }
    public static QueryDateExpressionValue getNextNFiscalYears(Integer years) { return new QueryDateExpressionValue('NEXT_N_FISCAL_YEARS:'+years); }
    public static QueryDateExpressionValue getLastNFiscalYears(Integer years) { return new QueryDateExpressionValue('LAST_N_FISCAL_YEARS:'+years); }
}