/**********************************************************
@class            QueryUtilTest
@brief            Test class for QueryUtil
@bug              None
@todo             None
@version          V1.0
@author           Brendan Conniff
@date             8/23/19
@copyright        (c)2019 Fortimize.  All Rights Reserved. Unauthorized use is prohibited.
***********************************************************/
@isTest
public class QueryUtilTest {
    @isTest
    private static void testSelect() {
        System.assertEquals(
            'SELECT Test1__c,Test2__c,Test3__r.Id FROM Table__c',
            QueryUtil.getSelect(new List<String>{ 'Test1__c', 'Test2__c', 'Test3__r.Id' }, 'Table__c').toString()
        );
    }

    @isTest
    private static void testSelectWithSimpleOrder() {
        System.assertEquals(
            'SELECT Id FROM Table__c ORDER BY Test1__c',
            QueryUtil.getSelect(new List<String>{ 'Id' }, 'Table__c').withOrder('Test1__c').toString()
        );
    }

    @isTest
    private static void testSelectWithSetOfFields() {
        System.assertEquals(
            'SELECT Id FROM Table__c',
            QueryUtil.getSelect(new Set<String>{ 'Id' }, 'Table__c').toString()
        );
    }

    @isTest
    private static void testSelectWithConditionsOrderLimitAndOffset() {
        System.assertEquals(
            'SELECT Test1__c,Test2__c,Test3__r.Id ' +
            'FROM Table__c ' +
            'WHERE (Test1__c=\'ABC\' AND Test2__c!=2019-08-23 AND Test3__r.Value__c>7) ' +
            'ORDER BY Test1__c,Test2__c ASC NULLS LAST,Test3__r.Name DESC,Test4__c NULLS FIRST ' +
            'LIMIT 20 ' +
            'OFFSET 50',
            QueryUtil.getSelect(new List<String>{ 'Test1__c', 'Test2__c', 'Test3__r.Id' }, 'Table__c')
                .withCondition(
                    QueryUtil.getAnd(
                        new List<QueryUtil.QueryCondition>{
                            QueryUtil.getEq('Test1__c', 'ABC'),
                            QueryUtil.getNotEq('Test2__c', Date.newInstance(2019, 8, 23)),
                            QueryUtil.getGt('Test3__r.Value__c', 7)
                        }
                    )
                )
                .withOrder(
                    QueryUtil.buildOrder()
                        .orderBy('Test1__c')
                        .thenBy('Test2__c')
                        .ascending()
                        .nullsLast()
                        .thenBy('Test3__r.Name')
                        .descending()
                        .thenBy('Test4__c')
                        .nullsFirst()
                )
                .withLimit(20)
                .withOffset(50)
                .toString()
        );
    }

    @isTest
    private static void testSelectSubqueries() {
        System.assertEquals(
            'SELECT Id,(SELECT Id,Name FROM Child_Object__r) ' +
            'FROM Table__c ' +
            'WHERE (Test1__c IN (SELECT Table__c FROM Other_Object__c) ' +
            'AND Test2__c NOT IN (SELECT Table__c FROM Another_Object__c))',
            QueryUtil.getSelect(
                    QueryUtil.buildSelection()
                        .add('Id')
                        .add(QueryUtil.getSelect(new List<String>{ 'Id', 'Name' }, 'Child_Object__r')),
                    'Table__c'
                )
                .withCondition(
                    QueryUtil.getAnd(
                        new List<QueryUtil.QueryCondition>{
                            QueryUtil.getIn(
                                'Test1__c',
                                QueryUtil.getSelect(new List<String>{ 'Table__c' }, 'Other_Object__c')
                            ),
                            QueryUtil.getNotIn(
                                'Test2__c',
                                QueryUtil.getSelect(new List<String>{ 'Table__c' }, 'Another_Object__c')
                            )
                        }
                    )
                )
                .toString()
        );
    }

    @isTest
    private static void testComplexConditions() {
        System.assertEquals(
            '(' +
            'Test1__c=true OR ' +
            'Test2__c>2019-08-23T12:30:59Z OR ' +
            'Test3__c IN (\'A\',\'B\',\'C\',null) OR (' +
            'Test1__c NOT IN (false,null) AND ' +
            'Test2__c IN (2019-08-28T18:30:30Z)' +
            ')' +
            ')',
            QueryUtil.getOr(
                    new List<QueryUtil.QueryCondition>{
                        QueryUtil.getOr(
                            new List<QueryUtil.QueryCondition>{ // OR with single item should not be parenthesized
                                QueryUtil.getEq('Test1__c', true)
                            }
                        ),
                        QueryUtil.getAnd(
                            new List<QueryUtil.QueryCondition>{ // AND with single item should not be parenthesized
                                QueryUtil.getGt('Test2__c', Datetime.newInstanceGmt(2019, 8, 23, 12, 30, 59))
                            }
                        ),
                        QueryUtil.getIn('Test3__c', new List<String>{ 'A', 'B', 'C', null }),
                        QueryUtil.getAnd(
                            new List<QueryUtil.QueryCondition>{
                                QueryUtil.getNotIn('Test1__c', new List<Boolean>{ false, null }),
                                QueryUtil.getIn(
                                    'Test2__c',
                                    new List<Datetime>{ Datetime.newInstanceGmt(2019, 8, 28, 18, 30, 30) }
                                )
                            }
                        )
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testOrAlwaysTrue() {
        System.assertEquals(
            'Id!=null',
            QueryUtil.getOr(
                    new List<QueryUtil.QueryCondition>{
                        QueryUtil.getEq('Test1__c', true),
                        QueryUtil.getNotIn('Test1__c', new List<Boolean>()) // this condition is always true, therefore the OR is always true
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testOrAlwaysFalse() {
        System.assertEquals(
            'Id=null',
            QueryUtil.getOr(
                    new List<QueryUtil.QueryCondition>{ // all child conditions are always false, therefore the OR is always false
                        QueryUtil.getIn('Test3__c', new List<String>()),
                        QueryUtil.getIn('Test1__c', new List<Boolean>())
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testAndAlwaysFalse() {
        System.assertEquals(
            'Id=null',
            QueryUtil.getAnd(
                    new List<QueryUtil.QueryCondition>{
                        QueryUtil.getEq('Test1__c', true),
                        QueryUtil.getIn('Test1__c', new List<Boolean>()) // value cannot be in an empty list, therefore the AND is always false
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testAndAlwaysTrue() {
        System.assertEquals(
            'Id!=null',
            QueryUtil.getAnd(
                    new List<QueryUtil.QueryCondition>{ // all child conditions are always true, therefore the AND is always true
                        QueryUtil.getNotIn('Test3__c', new List<String>()),
                        QueryUtil.getNotIn('Test1__c', new List<Boolean>())
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testNotAlwaysTrue() {
        System.assertEquals('Id!=null', QueryUtil.getNot(QueryUtil.getIn('Test3__c', new List<String>())).toSoql());
    }

    @isTest
    private static void testNotAlwaysFalse() {
        System.assertEquals('Id=null', QueryUtil.getNot(QueryUtil.getNotIn('Test3__c', new List<String>())).toSoql());
    }

    @isTest
    private static void testSimpleConditions() {
        // null conditions
        System.assertEquals('Field__c=null', QueryUtil.getIsNull('Field__c').toSoql());
        System.assertEquals('Field__c!=null', QueryUtil.getIsNotNull('Field__c').toSoql());

        // equal conditions
        System.assertEquals('Field__c=\'ABC\'', QueryUtil.getEq('Field__c', 'ABC').toSoql());
        System.assertEquals('Field__c=true', QueryUtil.getEq('Field__c', true).toSoql());
        System.assertEquals('Field__c=3', QueryUtil.getEq('Field__c', 3).toSoql());
        System.assertEquals('Field__c=2019-08-28', QueryUtil.getEq('Field__c', Date.newInstance(2019, 8, 28)).toSoql());
        System.assertEquals(
            'Field__c=2018-08-28T09:30:27Z',
            QueryUtil.getEq('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );
        System.assertEquals('Field__c=THIS_MONTH', QueryUtil.getEq('Field__c', QueryUtil.THIS_MONTH).toSoql());

        // not equal conditions
        System.assertEquals('Field__c!=\'ABC\'', QueryUtil.getNotEq('Field__c', 'ABC').toSoql());
        System.assertEquals('Field__c!=true', QueryUtil.getNotEq('Field__c', true).toSoql());
        System.assertEquals('Field__c!=3', QueryUtil.getNotEq('Field__c', 3).toSoql());
        System.assertEquals(
            'Field__c!=2019-08-28',
            QueryUtil.getNotEq('Field__c', Date.newInstance(2019, 8, 28)).toSoql()
        );
        System.assertEquals(
            'Field__c!=2018-08-28T09:30:27Z',
            QueryUtil.getNotEq('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );

        // greater than conditions
        System.assertEquals('Field__c>3', QueryUtil.getGt('Field__c', 3).toSoql());
        System.assertEquals('Field__c>2019-08-28', QueryUtil.getGt('Field__c', Date.newInstance(2019, 8, 28)).toSoql());
        System.assertEquals(
            'Field__c>2018-08-28T09:30:27Z',
            QueryUtil.getGt('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );
        System.assertEquals('Field__c>THIS_MONTH', QueryUtil.getGt('Field__c', QueryUtil.THIS_MONTH).toSoql());

        // less than conditions
        System.assertEquals('Field__c<3', QueryUtil.getLt('Field__c', 3).toSoql());
        System.assertEquals('Field__c<2019-08-28', QueryUtil.getLt('Field__c', Date.newInstance(2019, 8, 28)).toSoql());
        System.assertEquals(
            'Field__c<2018-08-28T09:30:27Z',
            QueryUtil.getLt('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );
        System.assertEquals('Field__c<THIS_MONTH', QueryUtil.getLt('Field__c', QueryUtil.THIS_MONTH).toSoql());

        // greater than or equal conditions
        System.assertEquals('Field__c>=3', QueryUtil.getGe('Field__c', 3).toSoql());
        System.assertEquals(
            'Field__c>=2019-08-28',
            QueryUtil.getGe('Field__c', Date.newInstance(2019, 8, 28)).toSoql()
        );
        System.assertEquals(
            'Field__c>=2018-08-28T09:30:27Z',
            QueryUtil.getGe('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );

        // less than or equal conditions
        System.assertEquals('Field__c<=3', QueryUtil.getLe('Field__c', 3).toSoql());
        System.assertEquals(
            'Field__c<=2019-08-28',
            QueryUtil.getLe('Field__c', Date.newInstance(2019, 8, 28)).toSoql()
        );
        System.assertEquals(
            'Field__c<=2018-08-28T09:30:27Z',
            QueryUtil.getLe('Field__c', Datetime.newInstanceGmt(2018, 8, 28, 9, 30, 27)).toSoql()
        );

        // like conditions
        System.assertEquals('Field__c LIKE \'ABC\'', QueryUtil.getLike('Field__c', 'ABC').toSoql());
    }

    @isTest
    private static void testInListConditions() {
        // "IN"
        System.assertEquals(
            'Field__c IN (\'One\',\'Two\')',
            QueryUtil.getIn('Field__c', new List<String>{ 'One', 'Two' }).toSoql()
        );
        System.assertEquals('Field__c IN (1,2,3)', QueryUtil.getIn('Field__c', new List<Decimal>{ 1, 2, 3 }).toSoql());
        System.assertEquals(
            'Field__c IN (true,false)',
            QueryUtil.getIn('Field__c', new List<Boolean>{ true, false }).toSoql()
        );
        System.assertEquals(
            'Field__c IN (2019-01-01,2019-01-02)',
            QueryUtil.getIn('Field__c', new List<Date>{ Date.newInstance(2019, 1, 1), Date.newInstance(2019, 1, 2) })
                .toSoql()
        );
        System.assertEquals(
            'Field__c IN (2019-01-01T12:30:00Z,2019-01-02T12:30:00Z)',
            QueryUtil.getIn(
                    'Field__c',
                    new List<Datetime>{
                        Datetime.newInstanceGmt(2019, 1, 1, 12, 30, 0),
                        Datetime.newInstanceGmt(2019, 1, 2, 12, 30, 0)
                    }
                )
                .toSoql()
        );

        // "NOT IN"
        System.assertEquals(
            'Field__c NOT IN (\'One\',\'Two\')',
            QueryUtil.getNotIn('Field__c', new List<String>{ 'One', 'Two' }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (1,2,3)',
            QueryUtil.getNotIn('Field__c', new List<Decimal>{ 1, 2, 3 }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (true,false)',
            QueryUtil.getNotIn('Field__c', new List<Boolean>{ true, false }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (2019-01-01,2019-01-02)',
            QueryUtil.getNotIn('Field__c', new List<Date>{ Date.newInstance(2019, 1, 1), Date.newInstance(2019, 1, 2) })
                .toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (2019-01-01T12:30:00Z,2019-01-02T12:30:00Z)',
            QueryUtil.getNotIn(
                    'Field__c',
                    new List<Datetime>{
                        Datetime.newInstanceGmt(2019, 1, 1, 12, 30, 0),
                        Datetime.newInstanceGmt(2019, 1, 2, 12, 30, 0)
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testIdCollections() {
        Id id1 = Id.valueOf(SObjectType.Lead.getKeyPrefix() + '0'.repeat(12 - '1'.length()) + 1);
        Id id2 = Id.valueOf(SObjectType.Lead.getKeyPrefix() + '0'.repeat(12 - '2'.length()) + 2);

        System.assertEquals(
            'Field__c IN (\'' +
            id1 +
            '\',\'' +
            id2 +
            '\')',
            QueryUtil.getIn('Field__c', new List<Id>{ id1, id2 }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (\'' +
            id1 +
            '\',\'' +
            id2 +
            '\')',
            QueryUtil.getNotIn('Field__c', new List<Id>{ id1, id2 }).toSoql()
        );
        System.assertEquals('Field__c IN (\'' + id1 + '\')', QueryUtil.getIn('Field__c', new Set<Id>{ id1 }).toSoql());
        System.assertEquals(
            'Field__c NOT IN (\'' +
            id1 +
            '\')',
            QueryUtil.getNotIn('Field__c', new Set<Id>{ id1 }).toSoql()
        );
    }

    @isTest
    private static void testInSetConditions() {
        // only test set operations with single value sets since order isn't really guaranteed

        // "IN"
        System.assertEquals('Field__c IN (\'One\')', QueryUtil.getIn('Field__c', new Set<String>{ 'One' }).toSoql());
        System.assertEquals('Field__c IN (1)', QueryUtil.getIn('Field__c', new Set<Decimal>{ 1 }).toSoql());
        System.assertEquals('Field__c IN (true)', QueryUtil.getIn('Field__c', new Set<Boolean>{ true }).toSoql());
        System.assertEquals(
            'Field__c IN (2019-01-01)',
            QueryUtil.getIn('Field__c', new Set<Date>{ Date.newInstance(2019, 1, 1) }).toSoql()
        );
        System.assertEquals(
            'Field__c IN (2019-01-01T12:30:00Z)',
            QueryUtil.getIn('Field__c', new Set<Datetime>{ Datetime.newInstanceGmt(2019, 1, 1, 12, 30, 0) }).toSoql()
        );

        // "NOT IN"
        System.assertEquals(
            'Field__c NOT IN (\'One\')',
            QueryUtil.getNotIn('Field__c', new Set<String>{ 'One' }).toSoql()
        );
        System.assertEquals('Field__c NOT IN (1)', QueryUtil.getNotIn('Field__c', new Set<Decimal>{ 1 }).toSoql());
        System.assertEquals(
            'Field__c NOT IN (true)',
            QueryUtil.getNotIn('Field__c', new Set<Boolean>{ true }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (2019-01-01)',
            QueryUtil.getNotIn('Field__c', new Set<Date>{ Date.newInstance(2019, 1, 1) }).toSoql()
        );
        System.assertEquals(
            'Field__c NOT IN (2019-01-01T12:30:00Z)',
            QueryUtil.getNotIn('Field__c', new Set<Datetime>{ Datetime.newInstanceGmt(2019, 1, 1, 12, 30, 0) }).toSoql()
        );
    }

    @isTest
    private static void testNotConditions() {
        System.assertEquals(
            '(NOT Field__c LIKE \'ABC\')',
            QueryUtil.getNot(QueryUtil.getLike('Field__c', 'ABC')).toSoql()
        );
    }

    @isTest
    private static void testSelectSingleField() {
        System.assertEquals('SELECT Id FROM Table__c', QueryUtil.getSelect('Id', 'Table__c').toSoql());
    }

    @isTest
    private static void testIgnoreEmptyListCondition() {
        System.assertEquals(
            'SELECT Id FROM Table__c',
            QueryUtil.getSelect('Id', 'Table__c')
                .withCondition(QueryUtil.getAnd(new List<QueryUtil.QueryCondition>()))
                .toSoql()
        );

        System.assertEquals(
            'SELECT Id FROM Table__c',
            QueryUtil.getSelect('Id', 'Table__c')
                .withCondition(QueryUtil.getOr(new List<QueryUtil.QueryCondition>()))
                .toSoql()
        );

        System.assertEquals(
            'SELECT Id FROM Table__c',
            QueryUtil.getSelect('Id', 'Table__c').withCondition(null).toSoql()
        );
    }

    @isTest
    private static void testExceptionWhenConstructingEmptySelect() {
        QueryUtil.QueryFormatException caughtEx = null;
        try {
            QueryUtil.getSelect(new List<String>(), 'Table__c');
        } catch (QueryUtil.QueryFormatException ex) {
            caughtEx = ex;
        }
        System.assertNotEquals(null, caughtEx);
    }

    @isTest
    private static void testExceptionWhenConstructingSelectWithInvalidFieldName() {
        QueryUtil.QueryFormatException caughtEx = null;
        try {
            QueryUtil.getSelect(new List<String>{ 'Test Field' }, 'Table__c');
        } catch (QueryUtil.QueryFormatException ex) {
            caughtEx = ex;
        }
        System.assertNotEquals(null, caughtEx);
    }

    @isTest
    private static void testExceptionWhenConstructingSelectWithInvalidTableName() {
        QueryUtil.QueryFormatException caughtEx = null;
        try {
            QueryUtil.getSelect(new List<String>{ 'Test_Field__c' }, 'Table Name');
        } catch (QueryUtil.QueryFormatException ex) {
            caughtEx = ex;
        }
        System.assertNotEquals(null, caughtEx);
    }

    @isTest
    private static void testExceptionWhenBuildingOrderIncorrectly() {
        QueryUtil.QueryFormatException caughtEx = null;
        try {
            QueryUtil.buildOrder().ascending();
        } catch (QueryUtil.QueryFormatException ex) {
            caughtEx = ex;
        }
        System.assertNotEquals(null, caughtEx);
    }

    @isTest
    private static void testOverloadedAndConditions() {
        System.assertEquals(
            '(Field1__c=1 AND Field2__c=2)',
            QueryUtil.getAnd(QueryUtil.getEq('Field1__c', 1), QueryUtil.getEq('Field2__c', 2)).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 AND Field2__c=2 AND Field3__c=3)',
            QueryUtil.getAnd(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3)
                )
                .toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 AND Field2__c=2 AND Field3__c=3 AND Field4__c=4)',
            QueryUtil.getAnd(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3),
                    QueryUtil.getEq('Field4__c', 4)
                )
                .toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 AND Field2__c=2 AND Field3__c=3 AND Field4__c=4 AND Field5__c=5)',
            QueryUtil.getAnd(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3),
                    QueryUtil.getEq('Field4__c', 4),
                    QueryUtil.getEq('Field5__c', 5)
                )
                .toSoql()
        );
    }

    @isTest
    private static void testOverloadedOrConditions() {
        System.assertEquals(
            '(Field1__c=1 OR Field2__c=2)',
            QueryUtil.getOr(QueryUtil.getEq('Field1__c', 1), QueryUtil.getEq('Field2__c', 2)).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR Field2__c=2 OR Field3__c=3)',
            QueryUtil.getOr(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3)
                )
                .toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR Field2__c=2 OR Field3__c=3 OR Field4__c=4)',
            QueryUtil.getOr(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3),
                    QueryUtil.getEq('Field4__c', 4)
                )
                .toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR Field2__c=2 OR Field3__c=3 OR Field4__c=4 OR Field5__c=5)',
            QueryUtil.getOr(
                    QueryUtil.getEq('Field1__c', 1),
                    QueryUtil.getEq('Field2__c', 2),
                    QueryUtil.getEq('Field3__c', 3),
                    QueryUtil.getEq('Field4__c', 4),
                    QueryUtil.getEq('Field5__c', 5)
                )
                .toSoql()
        );
    }

    @isTest
    private static void testAndParentheticals() {
        System.assertEquals(
            'Field1__c=1',
            QueryUtil.getAnd(new List<QueryUtil.QueryCondition>{ QueryUtil.getEq('Field1__c', 1) }).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 AND Field2__c=2)',
            QueryUtil.getAnd(
                    new List<QueryUtil.QueryCondition>{
                        QueryUtil.getEq('Field1__c', 1),
                        QueryUtil.getEq('Field2__c', 2)
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testOrParentheticals() {
        System.assertEquals(
            'Field1__c=1',
            QueryUtil.getOr(new List<QueryUtil.QueryCondition>{ QueryUtil.getEq('Field1__c', 1) }).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR Field2__c=2)',
            QueryUtil.getOr(
                    new List<QueryUtil.QueryCondition>{
                        QueryUtil.getEq('Field1__c', 1),
                        QueryUtil.getEq('Field2__c', 2)
                    }
                )
                .toSoql()
        );
    }

    @isTest
    private static void testParseOrder() {
        System.assertEquals(
            'SELECT Id FROM Table ORDER BY Field_1__c DESC,Field_2__c ASC NULLS FIRST',
            QueryUtil.getSelect(new List<String> { 'Id' }, 'Table')
                .withOrder(
                    QueryUtil.buildOrder().parse('Field_1__c DESC, Field_2__c ASC NULLS FIRST')
                )
                .toString()
        );
    }

    @isTest
    private static void testListConditionSameTypeNesting() {
        System.assertEquals(
            '(Field1__c=1 AND Field2__c=1 AND Field3__c=1)',
            QueryUtil.getAnd(new List<QueryUtil.QueryCondition>{
                QueryUtil.getEq('Field1__c', 1),
                QueryUtil.getAnd(new List<QueryUtil.QueryCondition> {
                    QueryUtil.getEq('Field2__c', 1),
                    QueryUtil.getEq('Field3__c', 1)
                })
            }).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR Field2__c=1 OR Field3__c=1)',
            QueryUtil.getOr(new List<QueryUtil.QueryCondition>{
                QueryUtil.getEq('Field1__c', 1),
                QueryUtil.getOr(new List<QueryUtil.QueryCondition> {
                    QueryUtil.getEq('Field2__c', 1),
                    QueryUtil.getEq('Field3__c', 1)
                })
            }).toSoql()
        );
    }

    @isTest
    private static void testListConditionDifferentTypeNesting() {
        System.assertEquals(
            '(Field1__c=1 AND (Field2__c=1 OR Field3__c=1))',
            QueryUtil.getAnd(new List<QueryUtil.QueryCondition>{
                QueryUtil.getEq('Field1__c', 1),
                QueryUtil.getOr(new List<QueryUtil.QueryCondition> {
                    QueryUtil.getEq('Field2__c', 1),
                    QueryUtil.getEq('Field3__c', 1)
                })
            }).toSoql()
        );

        System.assertEquals(
            '(Field1__c=1 OR (Field2__c=1 AND Field3__c=1))',
            QueryUtil.getOr(new List<QueryUtil.QueryCondition>{
                QueryUtil.getEq('Field1__c', 1),
                QueryUtil.getAnd(new List<QueryUtil.QueryCondition> {
                    QueryUtil.getEq('Field2__c', 1),
                    QueryUtil.getEq('Field3__c', 1)
                })
            }).toSoql()
        );
    }

    @IsTest
    private static void testDateExpressionGetters() {
        System.assertEquals('Field__c=NEXT_N_DAYS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNDays(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_DAYS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNDays(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_WEEKS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNWeeks(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_WEEKS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNWeeks(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_MONTHS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNMonths(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_MONTHS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNMonths(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_QUARTERS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNQuarters(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_QUARTERS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNQuarters(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_YEARS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNYears(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_YEARS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNYears(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_FISCAL_QUARTERS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNFiscalQuarters(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_FISCAL_QUARTERS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNFiscalQuarters(30)).toSoql());
        System.assertEquals('Field__c=NEXT_N_FISCAL_YEARS:30', QueryUtil.getEq('Field__c', QueryUtil.getNextNFiscalYears(30)).toSoql());
        System.assertEquals('Field__c=LAST_N_FISCAL_YEARS:30', QueryUtil.getEq('Field__c', QueryUtil.getLastNFiscalYears(30)).toSoql());
    }

}