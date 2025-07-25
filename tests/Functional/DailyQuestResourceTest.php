<?php

namespace App\Tests\Functional;

use App\Factory\DragonTreasureFactory;
use Zenstruck\Foundry\Test\Factories;
use Zenstruck\Foundry\Test\ResetDatabase;

class DailyQuestResourceTest extends ApiTestCase
{
    use ResetDatabase;
    use Factories;

    public function testPatchCanUpdateStatus(): void
    {
        // quests need at least 3 items
        DragonTreasureFactory::createMany(5);

        $day = new \DateTimeImmutable('-2 day');
        $this->browser()
            ->patch('/api/quests/'.$day->format('Y-m-d'), [
                'json' => [
                    'status' => 'completed',
                ],
                'headers' => ['Content-Type' => 'application/merge-patch+json'],
            ])
            ->assertStatus(200)
            ->assertJsonMatches('status', 'completed')
        ;
    }
}
